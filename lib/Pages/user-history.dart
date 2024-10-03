import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:library_application/model/user.dart';
import 'package:library_application/model/books.dart';

class UserHistoryScreen extends StatefulWidget {
  final User user;

  const UserHistoryScreen({Key? key, required this.user}) : super(key: key);

  @override
  _UserHistoryScreenState createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> {
  List<Book> allBooks = [];
  List<Book> filteredBooks = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchBorrowedBooks();
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User'),
        content: Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> fetchBorrowedBooks() async {
    final response = await http.get(Uri.parse('http://192.168.1.5:3000/books'));

    if (response.statusCode == 200) {
      List<Book> books = List<Book>.from(
        json.decode(response.body).map((book) => Book.fromJson(book)),
      );

      // Filter the books that the user has borrowed thank chatgpt
      List<Book> borrowedBooks = books.where((book) => 
          book.copies.any((copy) => copy.borrowedByUserId == widget.user.userId)
      ).toList();

      setState(() {
        allBooks = borrowedBooks;
        filteredBooks = borrowedBooks;
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load books');
    }
  }

  void _deleteUser() async {
    final response = await http.delete(
      Uri.parse('http://192.168.1.5:3000/users/${widget.user.userId}'),
    );

    if (response.statusCode == 200) {
      print('User deleted successfully');
      Navigator.pop(context, true);
    } else {
      print('Failed to delete user');
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;

      if (query.isNotEmpty) {
        // Filter books by book_copy_id
        filteredBooks = allBooks.where((book) {
          return book.copies.any((copy) => copy.bookCopyId.contains(query));
        }).toList();
      } else {
        filteredBooks = allBooks;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('User History'),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                bool confirmDelete = await _confirmDelete(context);
                if (confirmDelete) {
                  _deleteUser();
                }
              },
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.user.username,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Borrow: ${filteredBooks.length}'),
                        SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search by Book Copy ID',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: _onSearchChanged,
                        ),
                        SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredBooks.length,
                            itemBuilder: (context, index) {
                              final book = filteredBooks[index];
                              final userCopies = book.copies.where((copy) => copy.borrowedByUserId == widget.user.userId).toList();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: userCopies.map((copy) {
                                  return ListTile(
                                    title: Text(book.title),
                                    subtitle: Text('Copy ID: ${copy.bookCopyId}'),
                                    trailing: Builder(
                                      builder: (context) {
                                        bool isOverdue = copy.returnDate != null && DateTime.now().isAfter(copy.returnDate!);
                                        return isOverdue
                                          ? Text(
                                              'Overdue',
                                              style: TextStyle(color: Colors.red),
                                            )
                                          : Text('On Time', style: TextStyle(color: Colors.green));
                                      },
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
