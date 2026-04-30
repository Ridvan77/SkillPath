using SkillPath.Worker;

var builder = Host.CreateDefaultBuilder(args);

builder.ConfigureServices((context, services) =>
{
    services.AddHostedService<EmailWorker>();
});

var host = builder.Build();
host.Run();
