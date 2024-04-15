from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroSerializer
from confluent_kafka import SerializingProducer


def run_producer(matched_items,prompt_details,producer_conf,schema_conf,kafka_topic_name):
    matched_indexes = [entry[0].id for entry in matched_items]
    prompt_matched_responses= {
        'prompt_details':prompt_details,
        'matched_indexes' : matched_indexes
    }
    latest_version_schema ,sr = create_produce_client(schema_conf,kafka_topic_name)
    produce_search_results(prompt_matched_responses,kafka_topic_name,producer_conf,sr,latest_version_schema)
    return "Matched results published successfully"

def create_produce_client(schema_conf,kafka_topic_name):

    sr = SchemaRegistryClient(schema_conf)
    latest_version = sr.get_latest_version(f"{kafka_topic_name}-value")

    print(latest_version.schema.schema_str)
    return latest_version,sr

def produce_search_results(message,topic,producer_conf,sr,latest_version):
    value_avro_serializer = AvroSerializer(schema_registry_client = sr,
                                          schema_str = latest_version.schema.schema_str,
                                          conf={
                                              'auto.register.schemas': False
                                            }
                                          )
    producer = SerializingProducer({
        'bootstrap.servers': producer_conf['bootstrap.servers'],
        'security.protocol': 'SASL_SSL',
        'sasl.mechanisms':'PLAIN',
        'sasl.username': producer_conf['sasl.username'],
        'sasl.password':producer_conf['sasl.password'],
        'value.serializer': value_avro_serializer,
        'delivery.timeout.ms': 1000, 
        'enable.idempotence': 'true'
    })

    producer.produce(topic=topic,value=message)
    producer.flush()
    