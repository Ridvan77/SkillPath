using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;
using SkillPath.Services.DTOs;
using SkillPath.Services.Interfaces;

namespace SkillPath.Services.Services
{
    public class RabbitMQPublisherService : IRabbitMQPublisherService, IDisposable
    {
        private readonly ILogger<RabbitMQPublisherService> _logger;
        private readonly string _hostName;
        private readonly int _port;
        private readonly string _userName;
        private readonly string _password;
        private const string ExchangeName = "email_exchange";
        private const string QueueName = "email_queue";
        private const string RoutingKey = "email";

        private IConnection? _connection;
        private IChannel? _channel;
        private readonly SemaphoreSlim _semaphore = new(1, 1);
        private bool _disposed;

        public RabbitMQPublisherService(IConfiguration configuration, ILogger<RabbitMQPublisherService> logger)
        {
            _logger = logger;
            _hostName = Environment.GetEnvironmentVariable("RabbitMQ__HostName")
                ?? configuration["RabbitMQ:HostName"] ?? "localhost";
            _port = int.TryParse(Environment.GetEnvironmentVariable("RabbitMQ__Port"), out var p) ? p
                : configuration.GetValue<int?>("RabbitMQ:Port") ?? 5672;
            _userName = Environment.GetEnvironmentVariable("RabbitMQ__UserName")
                ?? configuration["RabbitMQ:UserName"] ?? "guest";
            _password = Environment.GetEnvironmentVariable("RabbitMQ__Password")
                ?? configuration["RabbitMQ:Password"] ?? "guest";

            _logger.LogInformation("RabbitMQ publisher configured: {Host}:{Port}", _hostName, _port);
        }

        private async Task EnsureConnectionAsync()
        {
            if (_connection is { IsOpen: true } && _channel is { IsOpen: true })
                return;

            await _semaphore.WaitAsync();
            try
            {
                if (_connection is { IsOpen: true } && _channel is { IsOpen: true })
                    return;

                // Clean up old connection
                try { if (_channel != null) await _channel.CloseAsync(); } catch { }
                try { if (_connection != null) await _connection.CloseAsync(); } catch { }

                var factory = new ConnectionFactory
                {
                    HostName = _hostName,
                    Port = _port,
                    UserName = _userName,
                    Password = _password
                };

                _connection = await factory.CreateConnectionAsync();
                _channel = await _connection.CreateChannelAsync();

                await _channel.ExchangeDeclareAsync(
                    exchange: ExchangeName,
                    type: ExchangeType.Direct,
                    durable: true,
                    autoDelete: false);

                await _channel.QueueDeclareAsync(
                    queue: QueueName,
                    durable: true,
                    exclusive: false,
                    autoDelete: false);

                await _channel.QueueBindAsync(
                    queue: QueueName,
                    exchange: ExchangeName,
                    routingKey: RoutingKey);

                _logger.LogInformation("RabbitMQ connection established to {Host}:{Port}", _hostName, _port);
            }
            finally
            {
                _semaphore.Release();
            }
        }

        public async Task PublishEmailAsync(EmailMessage message)
        {
            try
            {
                await EnsureConnectionAsync();

                var json = JsonSerializer.Serialize(message);
                var body = Encoding.UTF8.GetBytes(json);

                var properties = new BasicProperties
                {
                    Persistent = true,
                    ContentType = "application/json"
                };

                await _channel!.BasicPublishAsync(
                    exchange: ExchangeName,
                    routingKey: RoutingKey,
                    mandatory: false,
                    basicProperties: properties,
                    body: body);

                _logger.LogInformation("Email message published to RabbitMQ for {ToEmail}: {Subject}",
                    message.ToEmail, message.Subject);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish email to RabbitMQ for {ToEmail}", message.ToEmail);
                // Reset connection so next attempt reconnects
                _connection = null;
                _channel = null;
                throw;
            }
        }

        public void Dispose()
        {
            if (_disposed) return;
            _disposed = true;

            try { _channel?.CloseAsync().GetAwaiter().GetResult(); } catch { }
            try { _connection?.CloseAsync().GetAwaiter().GetResult(); } catch { }
            _channel?.Dispose();
            _connection?.Dispose();
            _semaphore.Dispose();
        }
    }
}
