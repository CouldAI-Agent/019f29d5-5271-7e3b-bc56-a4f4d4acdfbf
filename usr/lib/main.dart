import 'package:flutter/material.dart';

void main() {
  runApp(const EstoqueApp());
}

class EstoqueApp extends StatelessWidget {
  const EstoqueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestão de Estoque',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
      },
    );
  }
}

class Pallet {
  final String produto;
  final String lote;

  Pallet({required this.produto, required this.lote});
}

class Rack {
  final int numero;
  // A map from shelf number (prateleira) to a list of pallets or a single pallet
  // Assuming 1 pallet per space for simplicity, or just a list of pallets per shelf.
  final Map<int, List<Pallet>> prateleiras;

  Rack({required this.numero, required this.prateleiras});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  // Dados simulados
  List<Rack> racks = [
    Rack(numero: 1, prateleiras: {
      1: [Pallet(produto: 'Maçã', lote: '01-001')],
      2: [],
      3: [],
    }),
    Rack(numero: 2, prateleiras: {
      1: [],
      2: [],
      3: [Pallet(produto: 'Limão', lote: '06-124')],
    }),
  ];

  void _adicionarRack() {
    setState(() {
      int novoNumero = racks.isEmpty ? 1 : racks.last.numero + 1;
      racks.add(Rack(
        numero: novoNumero,
        prateleiras: {1: [], 2: [], 3: []}, // 3 prateleiras por padrão
      ));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nova fila de rack adicionada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      BuscaEstoqueView(racks: racks),
      VisaoGeralRacksView(
        racks: racks,
        onAddRack: _adicionarRack,
        onUpdate: () => setState(() {}),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Estoque'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Visão Geral',
          ),
        ],
      ),
    );
  }
}

class BuscaEstoqueView extends StatefulWidget {
  final List<Rack> racks;

  const BuscaEstoqueView({super.key, required this.racks});

  @override
  State<BuscaEstoqueView> createState() => _BuscaEstoqueViewState();
}

class _BuscaEstoqueViewState extends State<BuscaEstoqueView> {
  final TextEditingController _buscaController = TextEditingController();
  List<Map<String, dynamic>> _resultados = [];

  void _buscar(String query) {
    if (query.isEmpty) {
      setState(() {
        _resultados = [];
      });
      return;
    }

    List<Map<String, dynamic>> resultados = [];
    final buscaLower = query.toLowerCase();

    for (var rack in widget.racks) {
      rack.prateleiras.forEach((prateleira, pallets) {
        for (var pallet in pallets) {
          if (pallet.produto.toLowerCase().contains(buscaLower) ||
              pallet.lote.toLowerCase().contains(buscaLower)) {
            resultados.add({
              'pallet': pallet,
              'rack': rack.numero,
              'prateleira': prateleira,
            });
          }
        }
      });
    }

    setState(() {
      _resultados = resultados;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _buscaController,
            decoration: const InputDecoration(
              labelText: 'Buscar Produto ou Placa/Lote (ex: Limão ou 06-124)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _buscar,
          ),
        ),
        Expanded(
          child: _resultados.isEmpty && _buscaController.text.isNotEmpty
              ? const Center(child: Text('Nenhum resultado encontrado.'))
              : ListView.builder(
                  itemCount: _resultados.length,
                  itemBuilder: (context, index) {
                    final item = _resultados[index];
                    final Pallet pallet = item['pallet'];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.pallet),
                        title: Text('${pallet.produto} - ${pallet.lote}'),
                        subtitle: Text('Rack: ${item['rack']} | Prateleira: ${item['prateleira']}'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class VisaoGeralRacksView extends StatelessWidget {
  final List<Rack> racks;
  final VoidCallback onAddRack;
  final VoidCallback onUpdate;

  const VisaoGeralRacksView({
    super.key,
    required this.racks,
    required this.onAddRack,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: racks.length,
            itemBuilder: (context, index) {
              final rack = racks[index];
              return Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rack ${rack.numero}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ...rack.prateleiras.entries.map((entry) {
                        int prateleira = entry.key;
                        List<Pallet> pallets = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Prateleira $prateleira',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle, color: Colors.teal),
                                    onPressed: () {
                                      _mostrarModalAdicionarPallet(
                                        context,
                                        rack,
                                        prateleira,
                                      );
                                    },
                                    tooltip: 'Adicionar Palete',
                                  )
                                ],
                              ),
                              if (pallets.isEmpty)
                                const Text('Vazia', style: TextStyle(color: Colors.grey))
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: pallets.map((pallet) {
                                    return Chip(
                                      label: Text('${pallet.produto}\n${pallet.lote}'),
                                      backgroundColor: Colors.teal.shade50,
                                      onDeleted: () {
                                        pallets.remove(pallet);
                                        onUpdate();
                                      },
                                    );
                                  }).toList(),
                                )
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: onAddRack,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Fila de Rack'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              padding: const EdgeInsets.all(16),
            ),
          ),
        )
      ],
    );
  }

  void _mostrarModalAdicionarPallet(BuildContext context, Rack rack, int prateleira) {
    final produtoController = TextEditingController();
    final loteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Adicionar Palete (Rack ${rack.numero}, Prat. $prateleira)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: produtoController,
                decoration: const InputDecoration(labelText: 'Produto (ex: Limão)'),
              ),
              TextField(
                controller: loteController,
                decoration: const InputDecoration(labelText: 'Placa/Lote (ex: 06-124)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (produtoController.text.isNotEmpty && loteController.text.isNotEmpty) {
                  rack.prateleiras[prateleira]!.add(
                    Pallet(
                      produto: produtoController.text,
                      lote: loteController.text,
                    ),
                  );
                  onUpdate();
                  Navigator.pop(context);
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }
}
