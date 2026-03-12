using System.ComponentModel;
using ModelContextProtocol.Server;

namespace fx2dotnet;

[McpServerToolType]
internal static class Tools
{
    [McpServerTool]
    [Description("Returns pong so clients can verify the server is responsive.")]
    public static string Ping() => "pong";
}
