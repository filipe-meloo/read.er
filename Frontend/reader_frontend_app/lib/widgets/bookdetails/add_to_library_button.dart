import 'package:flutter/material.dart';
import '/dtos/search_book_dto.dart';
import '/services/personal_library_service.dart';
import 'package:intl/intl.dart';

class AddToLibraryButton extends StatelessWidget {
  final SearchBookDto book;

  const AddToLibraryButton({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        _showAddToLibraryDialog(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF6A4C93), // Substitui 'primary' por 'backgroundColor'
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      ),
      child: Text(
        'Adicionar à Biblioteca',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showAddToLibraryDialog(BuildContext context) {
    String? selectedStatus;
    DateTime? selectedDate;
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    bool isAdding = false; // Para exibir o indicador de carregamento

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Color(0xFF1E0F29),
              title: Text(
                'Adicionar à Biblioteca',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedStatus,
                    dropdownColor: Color(0xFF1E0F29),
                    hint: Text(
                      'Selecione o status',
                      style: TextStyle(color: Colors.white),
                    ),
                    isExpanded: true,
                    items: ['TBR', 'CURRENT_READ', 'READ'].map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(
                          status,
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedStatus = newValue;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  if (selectedStatus == 'READ')
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDate == null
                                ? 'Selecione a data em que o livro foi lido'
                                : 'Data: ${dateFormat.format(selectedDate!)}',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.calendar_today, color: Colors.white),
                          onPressed: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                              builder: (BuildContext context, Widget? child) {
                                return Theme(
                                  data: ThemeData.dark(),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  if (isAdding)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: CircularProgressIndicator(
                        color: Colors.purple,
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: isAdding
                      ? null
                      : () async {
                    if (selectedStatus == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                            Text('Por favor, selecione o status.')),
                      );
                      return;
                    }

                    if (selectedStatus == 'READ' &&
                        selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'A data em que o livro foi lido é obrigatória para o status "READ".')),
                      );
                      return;
                    }

                    setState(() {
                      isAdding = true;
                    });

                    try {
                      await PersonalLibraryService.addBookToLibrary(
                        book.volumeId,
                        book.title,
                        selectedStatus!,
                        selectedDate,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Livro adicionado à biblioteca com sucesso!')),
                      );
                      Navigator.of(context).pop();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Erro ao adicionar livro: $e')),
                      );
                    } finally {
                      setState(() {
                        isAdding = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6A4C93),
                  ),
                  child: Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
