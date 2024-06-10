
from confluent_kafka import Producer
from confluent_kafka.serialization import StringSerializer, SerializationContext, MessageField
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroSerializer
import os 
import json
import argparse
import random




class Context(object):
    def __init__(self, ProductImageIndexID, ProductDescription, ProductId, ProductImageGCSUri,ProductAttributes,ProductTextIndexID):
        self.ProductImageIndexID = ProductImageIndexID
        self.ProductDescription = ProductDescription
        self.ProductId = ProductId
        self.ProductImageGCSUri = ProductImageGCSUri
        self.ProductAttributes = ProductAttributes
        self.ProductTextIndexID = ProductTextIndexID


def prompt_to_dict(prompt, ctx):
    return dict(ProductImageIndexID=prompt.ProductImageIndexID,
                ProductDescription=prompt.ProductDescription,
                ProductId=prompt.ProductId,ProductImageGCSUri=prompt.ProductImageGCSUri,ProductAttributes=prompt.ProductAttributes,ProductTextIndexID=prompt.ProductTextIndexID)

def read_ccloud_config(config_file):
    omitted_fields = set([])
    conf = {}
    with open(config_file) as fh:
        for line in fh:
            line = line.strip()
            if len(line) != 0 and line[0] != "#":
                parameter, value = line.strip().split('=', 1)
                if parameter not in omitted_fields:
                    conf[parameter] = value.strip()
    return conf



def delivery_report(err, msg):
    if err is not None:
        print("Delivery failed for User record {}: {}".format(msg.key(), err))
        return
    print('User record {} successfully produced to {} [{}] at offset {}'.format(
        msg.key(), msg.topic(), msg.partition(), msg.offset()))

def run_producer(prompt_details,conf,producer):
    produce_search_results(prompt_details,conf['context_topic_name'],producer)
    return "Matched results published successfully"


def produce_search_results(message,topic,producer):
    producer.produce(topic=topic,
                             value=avro_serializer(message, SerializationContext(topic, MessageField.VALUE)),on_delivery=delivery_report)
    producer.flush()
    
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate JSON object based on Avro schema")

    random_int = random.randint(999568, 1099567)
    print(random_int)
    ProductImageIndexID = f"{random_int}_image"
    ProductDescription = input("Please enter ProductDescription: ")
    ProductId = random_int
    ProductImageGCSUri = input("Please enter ProductImageGCSUri: ")
    ProductAttributes = "{\"product_attributes\": [{\"attribute_name\": \"Color\", \"attribute_value\": \"Blue\"}, {\"attribute_name\": \"Size\", \"attribute_value\": \"Medium\"}, {\"attribute_name\": \"Material\", \"attribute_value\": \"Cotton\"}, {\"attribute_name\": \"Pattern\", \"attribute_value\": \"CindrellaCostume\"}]}"
    ProductTextIndexID = f"{random_int}_text"
    
    prompt = Context(ProductImageIndexID=ProductImageIndexID,
                        ProductDescription=ProductDescription,
                        ProductId=ProductId,
                        ProductImageGCSUri=ProductImageGCSUri,
                        ProductAttributes=ProductAttributes,
                        ProductTextIndexID=ProductTextIndexID)
            

    conf = read_ccloud_config("client.properties")
    sr = SchemaRegistryClient( {
            'url':conf['schema.registry.url'],
    'basic.auth.user.info': conf['schema.registry.basic.auth.user.info']
    })
    

    path = os.path.realpath(os.path.dirname(__file__))
    with open(f"{path}/avro/context.avsc") as f:
        schema_str = f.read()
    avro_serializer = AvroSerializer(sr,
                                     schema_str,
                                     prompt_to_dict)

    producer_conf = {
        'bootstrap.servers': conf['bootstrap.servers'],
        'security.protocol': 'SASL_SSL',
        'sasl.mechanisms':'PLAIN',
        'sasl.username': conf['sasl.username'],
        'sasl.password':conf['sasl.password']
    }

    producer = Producer(producer_conf)

    run_producer(prompt_details=prompt,conf=conf,producer=producer)
