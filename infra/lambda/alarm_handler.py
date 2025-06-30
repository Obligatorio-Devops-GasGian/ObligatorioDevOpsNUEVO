import json
import datetime

def lambda_handler(event, context):
    print("Evento recibido:")
    print(json.dumps(event, indent=2))

    try:
        sns_message_raw = event['Records'][0]['Sns']['Message']
        sns_message = json.loads(sns_message_raw)  
    except (KeyError, json.JSONDecodeError) as e:
        print(f"Error al decodificar el mensaje SNS: {e}")
        return {"statusCode": 400, "body": "Formato de evento inesperado"}

    alarm_name = sns_message.get('AlarmName', 'Desconocida')
    new_state = sns_message.get('NewStateValue', 'UNKNOWN')
    reason     = sns_message.get('NewStateReason', 'Sin motivo')
    timestamp  = sns_message.get('StateChangeTime', str(datetime.datetime.now()))

    print(f"[ALARMA DETECTADA]")
    print(f"  Nombre     : {alarm_name}")
    print(f"  Estado     : {new_state}")
    print(f"  Motivo     : {reason}")
    print(f"  Timestamp  : {timestamp}")

    # Aquí podrías hacer más cosas, por ejemplo:
    # - Guardar en S3
    # - Escribir en DynamoDB
    # - Llamar a otra API
    # - Enviar otro SNS / Slack / Discord / etc.

    return {
        "statusCode": 200,
        "body": f"Alarma '{alarm_name}' procesada correctamente"
    }
