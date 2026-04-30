using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Configuration;

namespace SkillPath.Services.Services
{
    public static class EmailService
    {
        public static async Task SendEmailAsync(string toEmail, string subject, string body, IConfiguration config)
        {
            var smtpHost = config["Email:SmtpHost"] ?? "smtp.gmail.com";
            var smtpPort = config.GetValue<int?>("Email:SmtpPort") ?? 587;
            var smtpUser = config["Email:SmtpUser"] ?? string.Empty;
            var smtpPassword = config["Email:SmtpPassword"] ?? string.Empty;
            var fromEmail = config["Email:FromEmail"] ?? smtpUser;
            var fromName = config["Email:FromName"] ?? "SkillPath";
            var enableSsl = config.GetValue<bool?>("Email:EnableSsl") ?? true;

            using var client = new SmtpClient(smtpHost, smtpPort)
            {
                Credentials = new NetworkCredential(smtpUser, smtpPassword),
                EnableSsl = enableSsl
            };

            var mailMessage = new MailMessage
            {
                From = new MailAddress(fromEmail, fromName),
                Subject = subject,
                Body = body,
                IsBodyHtml = true
            };

            mailMessage.To.Add(new MailAddress(toEmail));

            await client.SendMailAsync(mailMessage);
        }
    }
}
