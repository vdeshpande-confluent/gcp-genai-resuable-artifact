from confluent_kafka import Producer
from confluent_kafka.serialization import StringSerializer, SerializationContext, MessageField
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroSerializer
import os 
import json
import argparse
import random




class Prompt(object):
    def __init__(self, prompt_id, text, image_url, session_id):
        self.prompt_id = prompt_id
        self.text = text
        self.image_url = image_url
        self.session_id = session_id


def prompt_to_dict(prompt, ctx):
    return dict(prompt_id=prompt.prompt_id,
                text=prompt.text,
                image_url=prompt.image_url,session_id=prompt.session_id)

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


def generate_json_object(prompt_id, text, image_url, session_id):
    json_object = {
        "prompt_id": prompt_id,
        "text": text,
        "image_url": image_url,
        "session_id":session_id
    }
    return json_object


def delivery_report(err, msg):
    if err is not None:
        print("Delivery failed for User record {}: {}".format(msg.key(), err))
        return
    print('User record {} successfully produced to {} [{}] at offset {}'.format(
        msg.key(), msg.topic(), msg.partition(), msg.offset()))

def run_producer(prompt_details,conf,producer):
    produce_search_results(prompt_details,conf['prompt_topic_name'],producer)
    return "Matched results published successfully"


def produce_search_results(message,topic,producer):
    producer.produce(topic=topic,
                             value=avro_serializer(message, SerializationContext(topic, MessageField.VALUE)),on_delivery=delivery_report)
    producer.flush()
    
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate JSON object based on Avro schema")
    prompt_id = f"prompt_{random.randint(201, 300)}"
    text = input("What do you want to today: ")
    image_url = input("Please enter a image_url to support your request: ")
    # image_url = "gs://confluent-gcp-next-24/raw-dataset/images/AAAACindrella/cindrella4.jpeg"
    session_id = random.randint(1, 3)
    
    prompt = Prompt(prompt_id=prompt_id,
                        text=text,
                        image_url=image_url,
                        session_id=session_id)
            

    conf = read_ccloud_config("client.properties")
    sr = SchemaRegistryClient( {
            'url':conf['schema.registry.url'],
    'basic.auth.user.info': conf['schema.registry.basic.auth.user.info']
    })

    

    path = os.path.realpath(os.path.dirname(__file__))
    with open(f"{path}/avro/prompt.avsc") as f:
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
    print(prompt_id, text)
