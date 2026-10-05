import 'package:flutter/material.dart';

void main() => runApp(const MeuApp());

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Compras',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const TelaLista(),
    );
  }
}

class Item {
  final String id;
  String nome;
  int quantidade;
  bool comprado;

  Item({
    required this.nome,
    this.quantidade = 1,
    this.comprado = false,
  }) : id = DateTime.now().microsecondsSinceEpoch.toString();
}

class TelaLista extends StatefulWidget {
  const TelaLista({super.key});

  @override
  State<TelaLista> createState() => _TelaListaState();
}

class _TelaListaState extends State<TelaLista> {
  final List<Item> itens = [];

  int get totalComprados => itens.where((i) => i.comprado).length;

  List<Item> get itensOrdenados => [
        ...itens.where((i) => !i.comprado),
        ...itens.where((i) => i.comprado),
      ];

  void mostrarMensagem(String texto, {SnackBarAction? acao}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(texto),
          action: acao,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> abrirFormulario({Item? item}) async {
    final Item? resultado = await Navigator.push<Item>(
      context,
      MaterialPageRoute(builder: (_) => TelaItem(itemInicial: item)),
    );

    if (resultado == null || !mounted) return;

    setState(() {
      if (item == null) {
        itens.add(resultado);
      } else {
        item.nome = resultado.nome;
        item.quantidade = resultado.quantidade;
      }
    });

    mostrarMensagem(
      item == null
          ? '${resultado.nome} adicionado à lista'
          : '${resultado.nome} atualizado',
    );
  }

  void alternarComprado(Item item, bool? valor) {
    setState(() => item.comprado = valor ?? false);
  }

  void removerItem(Item item) {
    final int indice = itens.indexOf(item);
    if (indice == -1) return;

    setState(() => itens.removeAt(indice));

    mostrarMensagem(
      '${item.nome} removido',
      acao: SnackBarAction(
        label: 'Desfazer',
        onPressed: () {
          setState(() {
            itens.insert(indice.clamp(0, itens.length), item);
          });
        },
      ),
    );
  }

  void limparComprados() {
    final removidos = itens.where((i) => i.comprado).toList();
    if (removidos.isEmpty) return;

    setState(() => itens.removeWhere((i) => i.comprado));
    mostrarMensagem('${removidos.length} item(ns) comprado(s) removido(s)');
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Compras'),
        actions: [
          if (totalComprados > 0)
            IconButton(
              tooltip: 'Limpar comprados',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: limparComprados,
            ),
        ],
      ),
      body: itens.isEmpty ? _estadoVazio(cores) : _conteudo(cores),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
    );
  }

  Widget _estadoVazio(ColorScheme cores) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 96, color: cores.outline),
            const SizedBox(height: 16),
            Text(
              'Sua lista está vazia',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Toque em "Adicionar" para incluir o primeiro item.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cores.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conteudo(ColorScheme cores) {
    final lista = itensOrdenados;
    final double progresso = totalComprados / itens.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$totalComprados de ${itens.length} comprados',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progresso,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: lista.length,
            itemBuilder: (context, indice) {
              final item = lista[indice];

              return Dismissible(
                key: ValueKey(item.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => removerItem(item),
                background: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  padding: const EdgeInsets.only(right: 24),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: cores.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.delete, color: cores.onErrorContainer),
                ),
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    onTap: () => abrirFormulario(item: item),
                    leading: Checkbox(
                      value: item.comprado,
                      onChanged: (v) => alternarComprado(item, v),
                    ),
                    title: Text(
                      item.nome,
                      style: TextStyle(
                        decoration: item.comprado
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: item.comprado ? cores.outline : null,
                      ),
                    ),
                    subtitle: Text('Quantidade: ${item.quantidade}'),
                    trailing: const Icon(Icons.edit_outlined, size: 20),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class TelaItem extends StatefulWidget {
  final Item? itemInicial;

  const TelaItem({super.key, this.itemInicial});

  @override
  State<TelaItem> createState() => _TelaItemState();
}

class _TelaItemState extends State<TelaItem> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController nomeController;
  late int quantidade;

  bool get editando => widget.itemInicial != null;

  @override
  void initState() {
    super.initState();
    nomeController =
        TextEditingController(text: widget.itemInicial?.nome ?? '');
    quantidade = widget.itemInicial?.quantidade ?? 1;
  }

  @override
  void dispose() {
    nomeController.dispose();
    super.dispose();
  }

  void salvar() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      Item(
        nome: nomeController.text.trim(),
        quantidade: quantidade,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editando ? 'Editar Item' : 'Novo Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: nomeController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => salvar(),
                decoration: const InputDecoration(
                  labelText: 'Nome do item',
                  prefixIcon: Icon(Icons.shopping_basket_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Digite o nome do item';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              Text(
                'Quantidade',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed:
                        quantidade > 1 ? () => setState(() => quantidade--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(
                    width: 72,
                    child: Text(
                      '$quantidade',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => setState(() => quantidade++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: salvar,
                icon: const Icon(Icons.check),
                label: Text(editando ? 'Salvar alterações' : 'Adicionar à lista'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}