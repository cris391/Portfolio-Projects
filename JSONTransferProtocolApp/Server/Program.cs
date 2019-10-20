using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Runtime.Serialization.Json;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Threading;

namespace Server
{
  static class Method
  {
    public const string Read = "read";
    public const string Create = "create";
    public const string Update = "update";
    public const string Delete = "delete";

    public static readonly string[] methods = { Read, Create, Update, Delete };
  }
  public class Response
  {
    public string Status { get; set; }
    public string Body { get; set; }
  }
  public class Request
  {
    public string Method { get; set; }
    public string Path { get; set; }
    public string Date { get; set; }
    public string Body { get; set; }
    public override string ToString()
    {
      return "Method: " + Method + ", Path: " + Path + ", Date: " + Date + ", Body: " + Body;
    }
  }

  class Program
  {
    static void Main(string[] args)
    {
      new Server(IPAddress.Parse("127.0.0.1"), 5000);
      Console.WriteLine("Server Started");
    }

  }
  class Server
  {
    TcpListener server = null;
    public Server(IPAddress localAddr, int port)
    {
      server = new TcpListener(localAddr, port);
      server.Start();
      StartListener();
    }

    public void StartListener()
    {
      try
      {
        while (true)
        {
          Console.WriteLine("Waiting for a connection...");
          var client = server.AcceptTcpClient();

          Console.WriteLine($"A client connected!");
          Thread t = new Thread(new ParameterizedThreadStart(HandleDevice));
          t.Start(client);

        }
      }
      catch (SocketException e)
      {
        Console.WriteLine("SocketException: {0}", e);
        server.Stop();
      }
    }

    public void HandleDevice(object obj)
    {
      TcpClient client = (TcpClient)obj;
      var stream = client.GetStream();
      Response response = new Response();

      var buffer = new byte[client.ReceiveBufferSize];
      int receiveBufferCount;
      try
      {
        // while ((receiveBufferCount = stream.Read(buffer, 0, buffer.Length)) != 0)
        // {
        // var msg = Encoding.UTF8.GetString(buffer, 0, buffer.Length);
        // Console.WriteLine(msg);
        var request = client.ReadRequest();
        if (request.Method == null)
        {
          response.Status = "missing method";
          // goto Finish;
        }
        if (request.Path == null)
        {
          response.Status += "missing resource";
        }
        if (request.Body == null)
        {
          response.Status += ", missing body";
        }
        if (request.Date == null)
        {
          response.Status += ", missing date";
          goto Finish;
        }

        if (!(Util.ArrayContains(Method.methods, request.Method)))
        {
          response.Status += "illegal method";
          goto Finish;
        }
        // check if date in correct format
        if (request.Date != null && request.Date.GetType() != typeof(System.Int64))
        {
          response.Status += ", illegal date";
          goto Finish;
        }

      Finish:
        //invalid json object in body
        if (request.Body != null)
        {
          try
          {
            var categoryFromJson = JsonSerializer.Deserialize<Request>(request.Body);
          }
          catch (System.Exception e)
          {
            Console.WriteLine(e);

            response.Status += ", illegal body";
          }
          response.Body = "Hello World";
          goto End;
        }

      End:
        if (request.Path != null && request.Path.Contains("/api"))
        {
          if (request.Path.Contains("/api/categories"))
          {
            var extractedId = Regex.Match(request.Path, @"\d+$").Value;

            if (extractedId == "")
            {
              response.Status = "4 Bad Request";
            }
            if (request.Path != "" && extractedId != "" && request.Method == "create")
            {
              response.Status = "4 Bad Request";
              response.Body = null;
            }
            Console.WriteLine(123);
            Console.WriteLine(extractedId);
            Console.WriteLine(request.Path);
            if (request.Path != "" && extractedId == "" && request.Method == "update")
            {
              response.Status = "4 Bad Request";
              response.Body = null;
            }
          }
          else
          {
            response.Status = "4 Bad Request";
          }
        }

        Console.WriteLine(request.ToString());
        Console.WriteLine("Status: ", response.Status);
        Console.WriteLine(response.Status);

        // implement some kind of cleanup if client sends close message(server sid)
        // if (msg == "exit2") client.Close();
        // Console.WriteLine("{1}: Received: {0}", msg, Thread.CurrentThread.ManagedThreadId);

        // var serializeObject = new DataContractJsonSerializer(typeof(Response));

        var serializedObj = JsonSerializer.Serialize<Response>(response, new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });
        var byteReplyMsg = Encoding.UTF8.GetBytes(serializedObj);
        stream.Write(byteReplyMsg, 0, byteReplyMsg.Length);
        Console.WriteLine("{1}: Sent: {0}", response, Thread.CurrentThread.ManagedThreadId);
        // }
      }
      catch (Exception e)
      {
        Console.WriteLine("Exception: {0}", e.ToString());
        client.Close();
      }
    }
  }
  public static class Util
  {
    public static Response ReadResponse(this TcpClient client)
    {
      var strm = client.GetStream();
      // Console.WriteLine(strm);
      //strm.ReadTimeout = 250;
      byte[] resp = new byte[2048];
      using (var memStream = new MemoryStream())
      {
        int bytesread = 0;
        do
        {
          bytesread = strm.Read(resp, 0, resp.Length);
          // Console.WriteLine(bytesread);
          // Console.WriteLine("@@@@@@@");
          // Console.WriteLine(bytesread);
          // Console.WriteLine("######");
          memStream.Write(resp, 0, bytesread);
          var responseData2 = Encoding.UTF8.GetString(memStream.ToArray());
        } while (bytesread == 2048);

        var responseData = Encoding.UTF8.GetString(memStream.ToArray());
        return JsonSerializer.Deserialize<Response>(responseData, new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });
      }
    }
    public static Request ReadRequest(this TcpClient client)
    {
      var strm = client.GetStream();
      //strm.ReadTimeout = 250;
      byte[] resp = new byte[2048];
      using (var memStream = new MemoryStream())
      {
        int bytesread = 0;
        do
        {
          bytesread = strm.Read(resp, 0, resp.Length);
          // Console.WriteLine(bytesread);
          // Console.WriteLine("@@@@@@@");
          // Console.WriteLine(bytesread);
          // Console.WriteLine("######");
          memStream.Write(resp, 0, bytesread);
          var responseData2 = Encoding.UTF8.GetString(memStream.ToArray());
        } while (bytesread == 2048);

        var requestData = Encoding.UTF8.GetString(memStream.ToArray());
        return JsonSerializer.Deserialize<Request>(requestData, new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });
      }
    }

    public static Boolean ArrayContains(string[] array, string stringToCheck)
    {
      if (stringToCheck == null)
      {
        return false;
      }
      foreach (string x in array)
      {
        if (stringToCheck.Contains(x))
        {
          return true;
        }
      }
      return false;
    }
  }
}