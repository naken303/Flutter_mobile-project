import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:library_application/Pages/book.dart';
import 'package:library_application/Pages/home.dart';
import 'package:library_application/Pages/transcation.dart';
import 'package:library_application/Pages/user-history.dart';
import 'package:library_application/model/user.dart';
import 'package:library_application/model/books.dart';  // Assuming you have a Book model

class UserListScreen extends StatefulWidget {
  final String userName;
  final int userId;

  const UserListScreen({
    super.key,
    required this.userName,
    required this.userId,
  });


  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<User> userList = [];
  List<User> filteredUserList = [];
  List<Book> bookList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsersAndBooks();
  }

  Future<void> fetchUsersAndBooks() async {
    final userResponse = await http.get(Uri.parse('http://192.168.1.5:3000/users/all'));
    final bookResponse = await http.get(Uri.parse('http://192.168.1.5:3000/books'));

    if (userResponse.statusCode == 200 && bookResponse.statusCode == 200) {
      setState(() {
        userList = List<User>.from(json.decode(userResponse.body).map((user) => User.fromJson(user)));
        filteredUserList = userList;

        bookList = List<Book>.from(json.decode(bookResponse.body).map((book) => Book.fromJson(book)));
        
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load users or books');
    }
  }

  int borrowedBooksCount(int userId) {
    return bookList
        .expand((book) => book.copies)
        .where((copy) => copy.borrowedByUserId == userId)
        .length;
  }

  void _showAddUserModal(BuildContext context) {
    String newUsername = '';
    String newPassword = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                      'Add new user',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(labelText: 'Username'),
                  onChanged: (value) {
                    newUsername = value;
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  onChanged: (value) {
                    newPassword = value;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await registerUser(newUsername, newPassword);
                    Navigator.pop(context);
                    fetchUsersAndBooks(); // Refresh the user list
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      filteredUserList = userList.where((user) {
        return user.username.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> registerUser(String username, String password) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.5:3000/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'role': 'user',
      }),
    );

    if (response.statusCode == 201) {
      print('User registered successfully');
    } else {
      throw Exception('Failed to register user');
    }
  }

  void _goToUserHistory(User user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserHistoryScreen(user: user)),
    );

    if (result == true) {
      // If a user was deleted, refresh the user list
      fetchUsersAndBooks(); // Refresh the list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 247, 242),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Books',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.brown,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
      appBar: AppBar(
        title: const Text('User List'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search username or id',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: _onSearchChanged
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showAddUserModal(context),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add new user', style: TextStyle(color: Colors.white),),
                        style: ElevatedButton.styleFrom(
                          iconColor: Colors.white,
                          backgroundColor: Colors.brown,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredUserList.length,
                      itemBuilder: (context, index) {
                        final user = filteredUserList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            title: Text('ID: ${user.userId}'),
                            subtitle: Text(user.username),
                            trailing: Text('Borrow: ${borrowedBooksCount(user.userId)}'),
                            onTap: () => _goToUserHistory(user),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
    );
  }

  int _selectedIndex = 3;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
        Navigator.push(context, MaterialPageRoute(builder: (context) => DashboardScreen(userName: widget.userName, userId: widget.userId)));
          break;
        case 1:
          Navigator.push(context, MaterialPageRoute(builder: (context) => BookGridScreen(userName: widget.userName, userId: widget.userId)));
          break;
        case 2:
          Navigator.push(context, MaterialPageRoute(builder: (context) => Transaction(userName: widget.userName, userId: widget.userId)));
          break;
        case 3:
          // you here boss.
          break;
      }
    });
  }

}
