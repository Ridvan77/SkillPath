using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using System.Text.Json;

namespace SkillPath.Worker
{
    public class EmailWorker : BackgroundService
    {
        private readonly ILogger<EmailWorker> _logger;
        private readonly IConfiguration _configuration;
        private IConnection? _connection;
        private IChannel? _channel;

        private const string ExchangeName = "email_exchange";
        private const string QueueName = "email_queue";
        private const string RoutingKey = "email";

        public EmailWorker(ILogger<EmailWorker> logger, IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("EmailWorker starting...");

            await ConnectWithRetryAsync(stoppingToken);

            if (_channel == null)
            {
                _logger.LogError("Failed to connect to RabbitMQ. EmailWorker stopping.");
                return;
            }

            var consumer = new AsyncEventingBasicConsumer(_channel);
            consumer.ReceivedAsync += async (sender, args) =>
            {
                var body = Encoding.UTF8.GetString(args.Body.ToArray());
                _logger.LogInformation("Received email message: {Body}", body);

                try
                {
                    var emailMessage = JsonSerializer.Deserialize<EmailMessageDto>(body, new JsonSerializerOptions
                    {
                        PropertyNameCaseInsensitive = true
                    });

                    if (emailMessage != null)
                    {
                        await SendEmailWithRetryAsync(emailMessage, maxRetries: 3);
                    }

                    await _channel.BasicAckAsync(args.DeliveryTag, false, stoppingToken);
                    _logger.LogInformation("Email sent and acknowledged successfully");
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to process email message");
                    await _channel.BasicNackAsync(args.DeliveryTag, false, true, stoppingToken);
                }
            };

            await _channel.BasicConsumeAsync(QueueName, false, consumer, stoppingToken);
            _logger.LogInformation("EmailWorker is now consuming messages from queue: {Queue}", QueueName);

            while (!stoppingToken.IsCancellationRequested)
            {
                await Task.Delay(1000, stoppingToken);
            }
        }

        private async Task ConnectWithRetryAsync(CancellationToken ct)
        {
            var hostName = Environment.GetEnvironmentVariable("RABBITMQ_HOSTNAME")
                ?? _configuration["RabbitMQ:HostName"] ?? "localhost";
            var port = int.Parse(Environment.GetEnvironmentVariable("RABBITMQ_PORT")
                ?? _configuration["RabbitMQ:Port"] ?? "5672");
            var userName = Environment.GetEnvironmentVariable("RABBITMQ_USERNAME")
                ?? _configuration["RabbitMQ:UserName"] ?? "guest";
            var password = Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD")
                ?? _configuration["RabbitMQ:Password"] ?? "guest";

            var factory = new ConnectionFactory
            {
                HostName = hostName,
                Port = port,
                UserName = userName,
                Password = password
            };

            for (int attempt = 1; attempt <= 10; attempt++)
            {
                try
                {
                    _logger.LogInformation("Connecting to RabbitMQ at {Host}:{Port} (attempt {Attempt}/10)", hostName, port, attempt);
                    _connection = await factory.CreateConnectionAsync(ct);
                    _channel = await _connection.CreateChannelAsync(cancellationToken: ct);

                    await _channel.ExchangeDeclareAsync(ExchangeName, ExchangeType.Direct, durable: true, cancellationToken: ct);
                    await _channel.QueueDeclareAsync(QueueName, durable: true, exclusive: false, autoDelete: false, cancellationToken: ct);
                    await _channel.QueueBindAsync(QueueName, ExchangeName, RoutingKey, cancellationToken: ct);
                    await _channel.BasicQosAsync(0, 1, false, ct);

                    _logger.LogInformation("Successfully connected to RabbitMQ");
                    return;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to connect to RabbitMQ (attempt {Attempt}/10)", attempt);
                    if (attempt < 10)
                    {
                        var delay = TimeSpan.FromSeconds(Math.Pow(2, attempt));
                        await Task.Delay(delay, ct);
                    }
                }
            }
        }

        private async Task SendEmailWithRetryAsync(EmailMessageDto message, int maxRetries)
        {
            for (int attempt = 1; attempt <= maxRetries; attempt++)
            {
                try
                {
                    await SendEmailAsync(message);
                    return;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to send email (attempt {Attempt}/{MaxRetries})", attempt, maxRetries);
                    if (attempt < maxRetries)
                    {
                        await Task.Delay(TimeSpan.FromSeconds(Math.Pow(2, attempt)));
                    }
                    else
                    {
                        throw;
                    }
                }
            }
        }

        private async Task SendEmailAsync(EmailMessageDto message)
        {
            var fromEmail = Environment.GetEnvironmentVariable("EMAIL_FROM_EMAIL")
                ?? _configuration["Email:FromEmail"] ?? "";
            var smtpHost = Environment.GetEnvironmentVariable("EMAIL_SMTP_HOST")
                ?? _configuration["Email:SmtpHost"] ?? "smtp.gmail.com";
            var smtpPort = int.Parse(Environment.GetEnvironmentVariable("EMAIL_SMTP_PORT")
                ?? _configuration["Email:SmtpPort"] ?? "587");
            var smtpUsername = Environment.GetEnvironmentVariable("EMAIL_SMTP_USERNAME")
                ?? _configuration["Email:SmtpUsername"] ?? "";
            var smtpPassword = Environment.GetEnvironmentVariable("EMAIL_SMTP_PASSWORD")
                ?? _configuration["Email:SmtpPassword"] ?? "";

            var mimeMessage = new MimeMessage();
            mimeMessage.From.Add(new MailboxAddress("SkillPath", fromEmail));
            mimeMessage.To.Add(MailboxAddress.Parse(message.ToEmail));
            mimeMessage.Subject = message.Subject;
            mimeMessage.Body = new TextPart("html") { Text = message.Body };

            using var client = new SmtpClient();
            await client.ConnectAsync(smtpHost, smtpPort, SecureSocketOptions.StartTls);
            await client.AuthenticateAsync(smtpUsername, smtpPassword);
            await client.SendAsync(mimeMessage);
            await client.DisconnectAsync(true);

            _logger.LogInformation("Email sent to {ToEmail} with subject: {Subject}", message.ToEmail, message.Subject);
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("EmailWorker stopping...");

            if (_channel != null)
            {
                await _channel.CloseAsync(cancellationToken);
                _channel.Dispose();
            }

            if (_connection != null)
            {
                await _connection.CloseAsync(cancellationToken);
                _connection.Dispose();
            }

            await base.StopAsync(cancellationToken);
        }
    }

    public class EmailMessageDto
    {
        public string ToEmail { get; set; } = string.Empty;
        public string Subject { get; set; } = string.Empty;
        public string Body { get; set; } = string.Empty;
        public string? TemplateName { get; set; }
    }
}
