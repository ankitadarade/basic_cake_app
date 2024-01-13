import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CartCubit(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Cake App',
        routes: {
          '/': (context) => CakesScreen(),
          '/cart': (context) => CartScreen(),
        },
        onGenerateRoute: (settings) {
          // Handle any undefined routes
          return MaterialPageRoute(builder: (context) => CakesScreen());
        },
        builder: (context, child) {
          return BlocListener<CartCubit, CartState>(
            listener: (context, state) {
              if (state.items.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('${state.items.last.cake.name} added to cart')),
                );
              } else if (state.items.isEmpty && state.prevItems.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cart is empty')),
                );
              }
            },
            child: child,
          );
        },
      ),
    );
  }
}

//Model

class Cake {
  final String id;
  final String name;
  final double price;
  final double weight;
  final String flavor;
  final String imageUrl;
  int quantity;

  Cake({
    required this.id,
    required this.name,
    required this.price,
    required this.weight,
    required this.flavor,
    required this.imageUrl,
    this.quantity = 0,
  });
}

class CartItem extends Equatable {
  final Cake cake;
  int quantity;

  CartItem({required this.cake, this.quantity = 0});

  CartItem copyWith({int? quantity}) {
    return CartItem(
      cake: cake,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [cake, quantity];
}

//Cart State

class CartState {
  final List<CartItem> items;
  final List<CartItem> prevItems;

  const CartState({this.items = const [], this.prevItems = const []});

  CartState copyWith({List<CartItem>? items, List<CartItem>? prevItems}) {
    return CartState(
      items: items ?? this.items,
      prevItems: prevItems ?? this.prevItems,
    );
  }
}

//Cart Cubit

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState());

  void addToCart(CartItem item) {
    final existingItemIndex =
        state.items.indexWhere((i) => i.cake.id == item.cake.id);
    if (existingItemIndex != -1) {
      emit(state.copyWith(
        items: [
          ...state.items.sublist(0, existingItemIndex),
          state.items[existingItemIndex]
              .copyWith(quantity: state.items[existingItemIndex].quantity + 1),
          ...state.items.sublist(existingItemIndex + 1),
        ],
      ));
    } else {
      emit(state.copyWith(items: [...state.items, item.copyWith(quantity: 1)]));
    }
  }

  void removeFromCart(CartItem item) {
    emit(state.copyWith(
      items: state.items.where((i) => i.cake.id != item.cake.id).toList(),
    ));
  }

  void updateQuantity(String cakeName, int newQuantity) {
    final itemIndex =
        state.items.indexWhere((item) => item.cake.name == cakeName);
    if (itemIndex != -1) {
      state.items[itemIndex].quantity = newQuantity;
      emit(CartState(items: state.items));
    }
  }
}

//Cake Screen

class CakesScreen extends StatelessWidget {
  final List<Cake> cakes = [
    Cake(
      id: '1',
      name: 'Chocolate Cake',
      price: 200.0,
      weight: 1.5,
      flavor: 'Chocolate',
      imageUrl:
          'https://handletheheat.com/wp-content/uploads/2015/03/Best-Birthday-Cake-with-milk-chocolate-buttercream-SQUARE.jpg',
    ),
    Cake(
      id: '2',
      name: 'Vanilla Cake',
      price: 247.0,
      weight: 1.2,
      flavor: 'Vanilla',
      imageUrl:
          'https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcRvHU4Eb9-ztKRz_q3Gx8XMqitDeBip1zbqU6zZH7GdQiktC4y5',
    ),
    Cake(
      id: '3',
      name: 'Red Velvet Cake',
      price: 300.0,
      weight: 1.8,
      flavor: 'Red Velvet',
      imageUrl:
          'https://res.cloudinary.com/insignia-flowera-in/images/f_auto,q_auto/v1688048056/Round-Creamy-Red-Velvet-Cake_72063afbe/Round-Creamy-Red-Velvet-Cake_72063afbe.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cakes'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: ListView.builder(
          itemCount: cakes.length,
          itemBuilder: (context, index) {
            final cake = cakes[index];
            return BlocBuilder<CartCubit, CartState>(
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: ListTile(
                    leading: Container(
                        height: 60,
                        width: 60,
                        child: Image.network(cake.imageUrl, fit: BoxFit.cover)),
                    title: Text(cake.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${cake.price.toString()}',
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Weight: ${cake.weight.toString()} kg',
                          ),
                          const SizedBox(height: 5),
                          Text('Flavor: ${cake.flavor}'),
                        ],
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 30,
                          width: 125,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                  size: 15,
                                ),
                                onPressed: () {
                                  final itemIndex = state.items.indexWhere(
                                      (i) => i.cake.name == cake.name);
                                  if (itemIndex != -1 &&
                                      state.items[itemIndex].quantity > 0) {
                                    context.read<CartCubit>().updateQuantity(
                                        cake.name,
                                        state.items[itemIndex].quantity - 1);
                                  }
                                },
                              ),
                              Container(
                                width: 25,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Center(
                                  child: Text(
                                    state.items
                                        .firstWhere(
                                            (i) => i.cake.name == cake.name,
                                            orElse: () => CartItem(
                                                cake: cake, quantity: 0))
                                        .quantity
                                        .toString(),
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  size: 15,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  final itemIndex = state.items.indexWhere(
                                      (i) => i.cake.name == cake.name);
                                  if (itemIndex != -1) {
                                    context.read<CartCubit>().updateQuantity(
                                        cake.name,
                                        state.items[itemIndex].quantity + 1);
                                  } else {
                                    context.read<CartCubit>().addToCart(
                                        CartItem(cake: cake, quantity: 1));
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        height: 40,
        width: 350,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          onPressed: () => Navigator.pushNamed(context, '/cart'),
          child: const Text('Go to Cart'),
        ),
      ),
    );
  }
}

//Cart Screen
class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        backgroundColor: Colors.red,
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return const Center(
              child: Text('Your cart is empty'),
            );
          }
          return ListView.builder(
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              if (item.quantity == 0) {
                return Container();
              }
              return ListTile(
                leading: SizedBox(
                    height: 60,
                    width: 60,
                    child: Image.network(item.cake.imageUrl)),
                title: Text(
                  item.cake.name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Price: ₹${item.cake.price.toString()}',
                ),
                trailing: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: Colors.red,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        color: Colors.white,
                        icon: const Icon(Icons.remove),
                        onPressed: item.quantity > 0
                            ? () => context.read<CartCubit>().updateQuantity(
                                item.cake.name, item.quantity - 1)
                            : null,
                      ),
                      Text(
                        item.quantity.toString(),
                        style: TextStyle(color: Colors.white),
                      ),
                      IconButton(
                        color: Colors.white,
                        icon: const Icon(Icons.add),
                        onPressed: () => context
                            .read<CartCubit>()
                            .updateQuantity(item.cake.name, item.quantity + 1),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
