using System.Security.Cryptography;

namespace SkillPath.Services.Helpers
{
    public static class ReservationCodeGenerator
    {
        private const string Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

        public static string Generate()
        {
            var code = new char[9];
            var bytes = RandomNumberGenerator.GetBytes(9);
            for (int i = 0; i < 9; i++)
            {
                code[i] = Chars[bytes[i] % Chars.Length];
            }
            return $"RES-{new string(code)}";
        }
    }
}
