namespace SkillPath.Services.Helpers
{
    public static class EmailTemplateHelper
    {
        public static string WelcomeEmail(string firstName, string lastName)
        {
            return $@"
<!DOCTYPE html>
<html>
<head><meta charset=""utf-8""></head>
<body style=""margin:0;padding:0;background-color:#f4f4f7;font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;"">
<table width=""100%"" cellpadding=""0"" cellspacing=""0"" style=""background-color:#f4f4f7;padding:40px 0;"">
<tr><td align=""center"">
<table width=""600"" cellpadding=""0"" cellspacing=""0"" style=""background-color:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08);"">

  <!-- Header -->
  <tr>
    <td style=""background:linear-gradient(135deg,#3F51B5,#303F9F);padding:32px 40px;text-align:center;"">
      <h1 style=""color:#ffffff;margin:0;font-size:24px;font-weight:700;"">SkillPath</h1>
      <p style=""color:rgba(255,255,255,0.85);margin:8px 0 0;font-size:14px;"">Dobrodosli na platformu</p>
    </td>
  </tr>

  <!-- Welcome Badge -->
  <tr>
    <td style=""padding:32px 40px 0;text-align:center;"">
      <div style=""display:inline-block;background-color:#e8eaf6;border-radius:50%;width:64px;height:64px;line-height:64px;font-size:32px;"">&#127891;</div>
      <h2 style=""color:#3F51B5;margin:16px 0 4px;font-size:20px;"">Dobrodosli, {firstName}!</h2>
      <p style=""color:#6b7280;margin:0;font-size:14px;"">Vasa registracija je uspjesno zavrsena.</p>
    </td>
  </tr>

  <!-- Content -->
  <tr>
    <td style=""padding:24px 40px;"">
      <table width=""100%"" cellpadding=""0"" cellspacing=""0"" style=""background-color:#f9fafb;border-radius:10px;padding:24px;"">
        <tr><td>
          <p style=""color:#374151;margin:0 0 12px;font-size:14px;line-height:1.6;"">
            Postovani {firstName} {lastName},
          </p>
          <p style=""color:#374151;margin:0 0 12px;font-size:14px;line-height:1.6;"">
            Hvala vam sto ste se registrovali na SkillPath! Sada mozete pregledati nasu ponudu kurseva i rezervisati termine koji vam odgovaraju.
          </p>
          <p style=""color:#374151;margin:0 0 12px;font-size:14px;line-height:1.6;"">
            Evo sta mozete uraditi:
          </p>
          <table width=""100%"" cellpadding=""0"" cellspacing=""0"" style=""margin:8px 0;"">
            <tr>
              <td style=""padding:8px 0;color:#374151;font-size:14px;"">&#128218; Pregledajte dostupne kurseve</td>
            </tr>
            <tr>
              <td style=""padding:8px 0;color:#374151;font-size:14px;"">&#128197; Rezervisite termine koji vam odgovaraju</td>
            </tr>
            <tr>
              <td style=""padding:8px 0;color:#374151;font-size:14px;"">&#11088; Ocijenite kurseve nakon zavrsetka</td>
            </tr>
          </table>
        </td></tr>
      </table>
    </td>
  </tr>

  <!-- Footer -->
  <tr>
    <td style=""background-color:#f9fafb;padding:24px 40px;text-align:center;border-top:1px solid #e5e7eb;"">
      <p style=""color:#9ca3af;margin:0 0 4px;font-size:12px;"">Hvala sto koristite SkillPath!</p>
      <p style=""color:#9ca3af;margin:0;font-size:11px;"">Ovaj email je automatski generisan. Molimo ne odgovarajte na njega.</p>
    </td>
  </tr>

</table>
</td></tr>
</table>
</body>
</html>";
        }

        public static string BroadcastNotificationEmail(string title, string content)
        {
            return $@"
<!DOCTYPE html>
<html>
<head><meta charset=""utf-8""></head>
<body style=""margin:0;padding:0;background-color:#f4f4f7;font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;"">
<table width=""100%"" cellpadding=""0"" cellspacing=""0"" style=""background-color:#f4f4f7;padding:40px 0;"">
<tr><td align=""center"">
<table width=""600"" cellpadding=""0"" cellspacing=""0"" style=""background-color:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08);"">

  <!-- Header -->
  <tr>
    <td style=""background:linear-gradient(135deg,#3F51B5,#303F9F);padding:32px 40px;text-align:center;"">
      <h1 style=""color:#ffffff;margin:0;font-size:24px;font-weight:700;"">SkillPath</h1>
      <p style=""color:rgba(255,255,255,0.85);margin:8px 0 0;font-size:14px;"">Obavjestenje</p>
    </td>
  </tr>

  <!-- Notification Badge -->
  <tr>
    <td style=""padding:32px 40px 0;text-align:center;"">
      <div style=""display:inline-block;background-color:#e8eaf6;border-radius:50%;width:64px;height:64px;line-height:64px;font-size:32px;"">&#128276;</div>
      <h2 style=""color:#3F51B5;margin:16px 0 4px;font-size:20px;"">{title}</h2>
    </td>
  </tr>

  <!-- Content -->
  <tr>
    <td style=""padding:24px 40px;"">
      <table width=""100%"" cellpadding=""0"" cellspacing=""0"" style=""background-color:#f9fafb;border-radius:10px;padding:24px;"">
        <tr><td>
          <p style=""color:#374151;margin:0;font-size:14px;line-height:1.6;"">
            {content}
          </p>
        </td></tr>
      </table>
    </td>
  </tr>

  <!-- Footer -->
  <tr>
    <td style=""background-color:#f9fafb;padding:24px 40px;text-align:center;border-top:1px solid #e5e7eb;"">
      <p style=""color:#9ca3af;margin:0 0 4px;font-size:12px;"">Hvala sto koristite SkillPath!</p>
      <p style=""color:#9ca3af;margin:0;font-size:11px;"">Ovaj email je automatski generisan. Molimo ne odgovarajte na njega.</p>
    </td>
  </tr>

</table>
</td></tr>
</table>
</body>
</html>";
        }

        public static string PasswordChangedEmail(string firstName, string lastName)
        {
            return $@"
<!DOCTYPE html>
<html>
<head><meta charset=""utf-8""></head>
<body style=""margin:0;padding:0;background-color:#f4f4f7;font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;"">
<table width=""100%"" cellpadding=""0"" cellspacing=""0"" style=""background-color:#f4f4f7;padding:40px 0;"">
<tr><td align=""center"">
<table width=""600"" cellpadding=""0"" cellspacing=""0"" style=""background-color:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08);"">
  <tr>
    <td style=""background:linear-gradient(135deg,#3F51B5,#303F9F);padding:32px 40px;text-align:center;"">
      <h1 style=""color:#ffffff;margin:0;font-size:24px;font-weight:700;"">SkillPath</h1>
      <p style=""color:rgba(255,255,255,0.85);margin:8px 0 0;font-size:14px;"">Sigurnosna obavijest</p>
    </td>
  </tr>
  <tr>
    <td style=""padding:32px 40px;text-align:center;"">
      <div style=""display:inline-block;background-color:#fff3cd;border-radius:50%;width:64px;height:64px;line-height:64px;font-size:32px;"">&#128274;</div>
      <h2 style=""color:#111827;margin:16px 0 8px;font-size:20px;"">Lozinka promijenjena</h2>
      <p style=""color:#6b7280;margin:0;font-size:14px;line-height:1.6;"">
        Postovani {firstName} {lastName},<br><br>
        Vasa lozinka za SkillPath nalog je uspjesno promijenjena.<br>
        Ako niste izvrsili ovu promjenu, molimo vas da odmah kontaktirate podrsku.
      </p>
    </td>
  </tr>
  <tr>
    <td style=""padding:0 40px 24px;text-align:center;"">
      <p style=""color:#6b7280;background-color:#f9fafb;padding:12px;border-radius:8px;font-size:13px;margin:0;"">
        Datum promjene: {DateTime.UtcNow:dd.MM.yyyy HH:mm} UTC
      </p>
    </td>
  </tr>
  <tr>
    <td style=""background-color:#f9fafb;padding:24px 40px;text-align:center;border-top:1px solid #e5e7eb;"">
      <p style=""color:#9ca3af;margin:0 0 4px;font-size:12px;"">Hvala sto koristite SkillPath!</p>
      <p style=""color:#9ca3af;margin:0;font-size:11px;"">Ovaj email je automatski generisan. Molimo ne odgovarajte na njega.</p>
    </td>
  </tr>
</table>
</td></tr>
</table>
</body>
</html>";
        }
    }
}
