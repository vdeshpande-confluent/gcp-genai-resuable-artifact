import json
import os 
import random
import argparse
from confluent_kafka import Producer
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroSerializer
from confluent_kafka.serialization import SerializationContext, MessageField

class PromptEmbedding(object):
    def __init__(self, prompt_details, matched_indexes):
        self.prompt_details = prompt_details
        self.matched_indexes = matched_indexes

def prompt_embedding_to_dict(prompt_embedding, ctx):
    return {
        "prompt_details": prompt_embedding.prompt_details,
        "matched_indexes": prompt_embedding.matched_indexes
    }


def generate_random_prompt_details(index):
    prompt_id = f"prompt_{index}"
    text = f"Sample prompt text {index}"
    image_url = f"https://example.com/image_{index}.jpg"
    session_id = random.randint(1, 1000)
    
    return {
        "prompt_id": prompt_id,
        "text": text,
        "image_url": image_url,
        "session_id": session_id
    }

def generate_matched_indexes():
    index_type = random.choice(["text", "image"])
    index_number = random.randint(301, 360)
    return [f"{index_type}_{index_number}"]

def generate_prompt_embedding_records(num_records):
    records = []
    for i in range(1, num_records + 1):
        prompt_details = generate_random_prompt_details(i)
        matched_indexes = generate_matched_indexes()
        
        record = {
            "prompt_details": prompt_details,
            "matched_indexes": matched_indexes
        }
        records.append(record)
    return records


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
        print("Delivery failed for Prompt Embedding record {}: {}".format(msg.key(), err))
        return
    print('Prompt Embedding record {} successfully produced to {} [{}] at offset {}'.format(
        msg.key(), msg.topic(), msg.partition(), msg.offset()))

def run_producer(prompt_embedding, conf, producer):
    produce_prompt_embedding(prompt_embedding, conf['prompt_embedding_topic_name'], producer)
    return "Prompt Embedding records published successfully"

def produce_prompt_embedding(prompt_embedding, topic, producer):
    producer.produce(
        topic=topic,
        value=avro_serializer(prompt_embedding, SerializationContext(topic, MessageField.VALUE)),
        on_delivery=delivery_report
    )
    producer.flush()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate Prompt Embedding records based on Avro schema")
    
    conf = read_ccloud_config("client.properties")
    sr = SchemaRegistryClient({
        'url': conf['schema.registry.url'],
        'basic.auth.user.info': conf['schema.registry.basic.auth.user.info']
    })

    path = os.path.realpath(os.path.dirname(__file__))
    with open(f"{path}/avro/prompt_embedding.avsc") as f:
        schema_str = f.read()
    avro_serializer = AvroSerializer(sr, schema_str, prompt_embedding_to_dict)

    producer_conf = {
        'bootstrap.servers': conf['bootstrap.servers'],
        'security.protocol': 'SASL_SSL',
        'sasl.mechanisms': 'PLAIN',
        'sasl.username': conf['sasl.username'],
        'sasl.password': conf['sasl.password']
    }

    producer = Producer(producer_conf)

    # Generated values for Prompt Embedding records
    # generated_values = [
    #     {
    #         "prompt_details": {
    #             "prompt_id": "prompt_1",
    #             "text": "Sample text 1",
    #             "image_url": "https://example.com/image_1.jpg",
    #             "session_id": 101
    #         },
    #         "matched_indexes": ["text_101", "image_102"]
    #     },
    #     {
    #         "prompt_details": {
    #             "prompt_id": "prompt_2",
    #             "text": "Sample text 2",
    #             "image_url": "https://example.com/image_2.jpg",
    #             "session_id": 102
    #         },
    #         "matched_indexes": ["text_103", "image_103"]
    #     },
    #     # Add more records here if needed
    # ]

    prompts = [
        PromptEmbedding(**value) for value in generate_prompt_embedding_records(10)
    ]

    for prompt in prompts:
        run_producer(prompt_embedding=prompt, conf=conf, producer=producer)
