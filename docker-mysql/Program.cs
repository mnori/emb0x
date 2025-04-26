// // See https://aka.ms/new-console-template for more information
// Console.WriteLine("Hello, World!");

using System;
using MySql.Data.MySqlClient;

namespace DockerMySQL {
    class Program {
        static void Main(string[] args) {
            string connectionString = "server=database;user=root;password=confidentcats4eva;database=mysql";

            System.Threading.Thread.Sleep(5000);

            try {
                using (MySqlConnection connection = new MySqlConnection(connectionString)) {
                    connection.Open();
                    connection.Close();
                }
            } catch (Exception ex) {
                Console.WriteLine(ex.ToString());
                Environment.Exit(1);
            }

            Console.WriteLine("Connected to MySQL!");
        }
    }
}