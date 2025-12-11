import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/library_book.dart';
import '../services/config.dart';

class ApiService {

    static Future<void> fetchData() async {
        print("Fetching data...");
        await Future.delayed(Duration(seconds: 2));
        print("Data fetched successfully!");
        }
    // Função de login (exemplo)
    static Future<bool> login(String email, String password) async {
        final url = Uri.parse('$BASE_URL/api/Auth/login');
        final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
        );

        if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final token = data['token'];

            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('jwtToken', token);

            return true;
        } else {
            throw Exception("Erro ao fazer login: ${response.body}");
        }
    }

    static Future<String> registerUser({
            required String username,
            required String email,
            required String password,
            required String nome,
            required String role,
            required String dob, 
            required String bio,
        }) async {
            final url = Uri.parse('$BASE_URL/api/Auth/registo');
            final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
                'username': username,
                'email': email,
                'password': password,
                'nome': nome,
                'role': role,
                'nascimento': dob,
                'isActive': true,
                'bio': bio
            }),
            );
                if (response.statusCode == 200) {
                final data = jsonDecode(response.body);
                    return "Registro bem-sucedido! Token: ${data['token']}";
            } else {
                throw Exception("Erro ao registrar: ${response.body}");
            }
  }

    static Future<Map<String, dynamic>?> fetchBookDetails(String isbn) async {
        try {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            String? token = prefs.getString('jwtToken');

            final response = await http.get(
                Uri.parse('$BASE_URL/api/Books/details/$isbn'),
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": "Bearer $token",
                },
            );

            if (response.statusCode == 200) {
                Map<String, dynamic> data = jsonDecode(response.body);

                if (data['pageCount'] != null) {
                    data['totalPages'] = data['pageCount'];
                }

                return data;
            } else {
                print("Failed to fetch book details for ISBN: $isbn");
                return null;
            }
        } catch (e) {
            print("Error fetching book details: $e");
            return null;
        }
    }


    static Future<List<LibraryBook>> fetchCurrentlyReadingBooks() async {
        try {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            String? token = prefs.getString('jwtToken');

            final response = await http.get(
                Uri.parse('$BASE_URL/api/PersonalLibrary/list-user-currentread-books'),
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": "Bearer $token",
                },
            );

            if (response.statusCode == 200) {
                List<dynamic> data = jsonDecode(response.body);
                return data.map((book) => LibraryBook.fromJson(book)).toList();
            } else {
                throw Exception("Failed to load currently reading books");
            }
        } catch (e) {
            print("Error: $e");
            return [];
        }
    }

    static Future<List<LibraryBook>> fetchToBeReadBooks() async {
        try {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            String? token = prefs.getString('jwtToken');

            final response = await http.get(
                Uri.parse('$BASE_URL/api/PersonalLibrary/list-user-tbr-books'),
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": "Bearer $token",
                },
            );

            if (response.statusCode == 200) {
                List<dynamic> data = jsonDecode(response.body);
                return data.map((book) => LibraryBook.fromJson(book)).toList();
            } else {
                throw Exception("Failed to load to be read books");
            }
        } catch (e) {
            print("Error: $e");
            return [];
        }
    }

    static Future<List<LibraryBook>> fetchReadBooks() async {
        try {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            String? token = prefs.getString('jwtToken');

            final response = await http.get(
                Uri.parse('$BASE_URL/api/PersonalLibrary/list-user-readed-books'),
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": "Bearer $token",
                },
            );

            if (response.statusCode == 200) {
                List<dynamic> data = jsonDecode(response.body);
                return data.map((book) => LibraryBook.fromJson(book)).toList();
            } else {
                throw Exception("Failed to load read books");
            }
        } catch (e) {
            print("Error: $e");
            return [];
        }
    }
    Future<void> fetchBookCover(String imageUrl) async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('jwtToken');

        final response = await http.get(
            Uri.parse('$BASE_URL/api/PersonalLibrary/book-cover-proxy?imageUrl=$imageUrl'),
            headers: {
                "Authorization": "Bearer $token", // Inclua o token JWT
                "Content-Type": "application/json",
            },
        );

        if (response.statusCode == 200) {
            // A requisição foi bem-sucedida
        } else {
            // Lidar com o erro
        }
        }

    Future<String?> getToken() async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        return prefs.getString('jwtToken');
    }
}