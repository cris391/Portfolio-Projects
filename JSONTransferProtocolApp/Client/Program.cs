using System;
using System.Net;
using System.Net.Sockets;
using System.Text;

namespace Client
{
  class Program
  {

    static void Main(string[] args)
    {
      ConnectClient();
    }

    static void ConnectClient()
    {
      try
      {
        var client = new TcpClient();
        client.Connect(IPAddress.Loopback, 5000);

        var stream = client.GetStream();

        while (true)
        {
          Console.WriteLine("Send message:");
          var msg = Console.ReadLine();

          if (msg == "exit") break;

          Console.WriteLine($"Sent: {msg}");
          var buffer = Encoding.UTF8.GetBytes(msg);

          // Send the message to the ConnectCliented TcpServer. 
          stream.Write(buffer, 0, buffer.Length);


          buffer = new byte[client.ReceiveBufferSize];

          // Read the Tcp Server Response Bytes.
          var rcnt = stream.Read(buffer, 0, buffer.Length);
          msg = Encoding.ASCII.GetString(buffer, 0, rcnt);
          Console.WriteLine("Received: {0}", msg);
        }

        stream.Close();
        client.Close();
      }
      catch (Exception e)
      {
        Console.WriteLine("Exception: {0}", e);
      }
    }
  }
}