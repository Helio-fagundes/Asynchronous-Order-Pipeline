#===============================================
#AWS SQS Queues
#===============================================
resource "aws_sqs_queue" "fila_pedidos_dlq" {
  name = "fila-pedidos-dlq"
}

resource "aws_sqs_queue" "fila_pedidos" {
  name = "fila-pedidos"

  receive_wait_time_seconds = 10

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.fila_pedidos_dlq.arn
    maxReceiveCount     = 3
  })
}

#===============================================
#AWS messasing
#===============================================
resource "aws_sns_topic" "notificacao_pipeline" {
  name = "notificacao-pipeline"
}

resource "aws_ses_email_identity" "email_identity" {
  email = var.email
}

#===============================================
#AWS lambda
#===============================================
resource "local_file" "lambda_code" {
  filename = "${path.module}/outputs/lambda_function.py"
  content  = <<EOF
import boto3
import json

ses_client = boto3.client('ses', region_name='us-east-1')

def lambda_handler(event, context):
    for record in event['Records']:
        mensagem_str = record['Sns']['Message']
        dados = json.loads(mensagem_str)

        email_cliente = dados.get('email_cliente')
        nome          = dados.get('nome_cliente', 'Cliente')
        status        = dados.get('status', 'PENDING')
        id_pedido     = dados.get('id_pedido', 'N/A')

        if status == "ACCEPTED":
            assunto = "🎉 Seu pedido foi aceito!"
            corpo = f"Ola {nome},\n\nSeu pedido {id_pedido} foi processado e ACEITO com sucesso!"
        else:
            assunto = "⚠️ Problema com seu pedido"
            corpo = f"Ola {nome},\n\nHouve um problema. Seu pedido {id_pedido} nao foi aceito."

        try:
            ses_client.send_email(
                Source='${aws_ses_email_identity.email_identity.email}',
                Destination={'ToAddresses': [email_cliente]},
                Message={
                    'Subject': {'Data': assunto},
                    'Body': {'Text': {'Data': corpo}}
                }
            )
            print(f"E-mail enviado com sucesso para {email_cliente}")
        except Exception as e:
            print(f"Erro ao enviar e-mail: {str(e)}")
EOF
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = local_file.lambda_code.filename
  output_path = "${path.module}/outputs/lambda_function.zip"
}

resource "aws_lambda_function" "notificador_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "notificador-dinamico-pipeline"
  role             = "arn:aws:iam::294892597124:role/lambda-pipeline-sns-ses-role"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notificador_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.notificacao_pipeline.arn
}

resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.notificacao_pipeline.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.notificador_lambda.arn
}