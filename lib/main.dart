import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String vtexAccount = "ssesandbox03";

VtexClientProfileData clientProfile = VtexClientProfileData(
    'carlos.lima@vtex.com.br', 'Carlos', 'Lima', '12345678', '987654321');

VtexShippingDataAddress shippingData = VtexShippingDataAddress(
    'residential',
    'Carlos Lima',
    '04726010',
    'Sao Paulo',
    'SP',
    'Brazil',
    'R. Visc de Taunay',
    '123',
    'Vila Cruzeiro',
    'AP X',
    'Near CHSA');

class VtexClientProfileData {
  String email;
  String firstName;
  String lastName;
  String document;
  String phone;

  VtexClientProfileData(
      this.email, this.firstName, this.lastName, this.document, this.phone);

  String toJSON() {
    return '{"email":"$email","firstName":"$firstName","lastName":"$lastName","document":"$document","phone":"$phone"}';
  }
}

class VtexShippingDataAddress {
  String addressType;
  String receiverName;
  String postalCode;
  String city;
  String state;
  String country;
  String street;
  String number;
  String neighbourhood;
  String complement;
  String reference;

  VtexShippingDataAddress(
      this.addressType,
      this.receiverName,
      this.postalCode,
      this.city,
      this.state,
      this.country,
      this.street,
      this.number,
      this.neighbourhood,
      this.complement,
      this.reference);

  String toJSON() {
    return '{"addressType":"$addressType","receiverName":"$receiverName","postalCode":"$postalCode","city":"$city","state":"$state","country":"$country","street":"$street","number":"$number","neighbourhood":"$neighbourhood","complement":"$complement","reference":"$reference"}';
  }
}

class VtexCartItem {
  String id;
  int quantity;
  String seller;
  int price;

  VtexCartItem(this.id, this.quantity, this.seller, this.price);

  void vtexCartItemFromProduct(
      Product p, int productQuantity, int productPrice, String productSeller) {
    id = p.productId;
    quantity = productQuantity;
    seller = productSeller;
    price = productPrice;
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const MyHomePage(title: 'VTEX Store: $vtexAccount'),
    );
  }
}

// fetch VTEX Product data
Future<Product> fetchProduct({int productIndex = 0}) async {
  const String vtexApiProductsSearch =
      'https://$vtexAccount.vtexcommercestable.com.br/api/catalog_system/pub/products/search?ft=camiseta';

  debugPrint("Will call this http endpoint: $vtexApiProductsSearch");

  final response = await http.get(Uri.parse(vtexApiProductsSearch));

  if ((response.statusCode == 200) || (response.statusCode == 206)) {
    debugPrint("Success... ${response.statusCode}");
    debugPrint("Body: ${response.body}");

    List<Product> products = (json.decode(response.body) as List)
        .map((data) => Product.fromJson(data))
        .toList();

    debugPrint("Found ${products.length} items");

    const String vtexApiProductsOffers =
        'https://$vtexAccount.vtexcommercestable.com.br/pub/products/offers/{productId}';

    return products.elementAt(productIndex);
  } else {
    debugPrint("Error...");
    throw Exception('Unable to read VTEX API Rest Endpoint');
  }
}

// 01 Simulate a Cart
Future<http.Response> simulateCart() async {
  const String vtexApiCartSimulation =
      'https://$vtexAccount.vtexcommercestable.com.br/api/checkout/pub/orderForms/simulation';

  debugPrint("Will call this http endpoint: $vtexApiCartSimulation");

  return http.post(Uri.parse(vtexApiCartSimulation),
      headers: <String, String>{'Content-Type': 'application/json'}, body: '''{
              "items": [{
                          "id": "166",
                          "productId": "34",
                          "quantity": 3,
                          "seller": 1
                        }],
              "country": "BRA",
              "postalCode": "04726-010"
             }''');
}

// 02 Get Client By Email
Future<http.Response> getClientProfileByEmail() async {
  const String vtexApiGetClientByEmail =
      'https://$vtexAccount.vtexcommercestable.com.br/api/checkout/pub/profiles?email=carlos.lima@vtex.com.br';

  debugPrint("Will call this http endpoint: $vtexApiGetClientByEmail");

  return http.get(Uri.parse(vtexApiGetClientByEmail),
      headers: <String, String>{'Content-Type': 'application/json'});
}

// 03 Build orderForm

// 04 Place the order
Future<http.Response> placeOrder() async {
  const String vtexApiPlaceOrder =
      'https://$vtexAccount.vtexcommercestable.com.br/api/checkout/pub/orders';

  debugPrint("Will call this http endpoint: $vtexApiPlaceOrder");

  return http.put(Uri.parse(vtexApiPlaceOrder),
      headers: <String, String>{'Content-Type': 'application/json'}, body: '''{
              "items": [{
                          "id": "166",
                          "productId": "34",
                          "quantity": 3,
                          "seller": 1
                        }]
             }''');
}

class Product {
  final String productId;
  final String productName;
  final String productTitle;
  final String productFirstImage;

  // constructor
  const Product(
      {required this.productId,
      required this.productName,
      required this.productTitle,
      required this.productFirstImage});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
        productId: json['productId'],
        productTitle: json['productTitle'],
        productName: json['productName'],
        productFirstImage: json['items'][0]['images'][0]['imageUrl']);
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int clickCounter = 0;

  void runSimulateCart() async {
    debugPrint("simulate cart runs...");

    http.Response responseSimulateCart = await simulateCart();
    debugPrint(responseSimulateCart.body);

    http.Response responseGetClientProfileByEmail =
        await getClientProfileByEmail();
    debugPrint(responseGetClientProfileByEmail.body);

    // Main Five Elements of an oderForm:
    //
    // items
    // clientProfileData
    // shippingData.address
    // shippingData.logisticsInfo
    // paymentData

    setState(() {
      clickCounter++;
    });
  }

  void runCheckout() {
    debugPrint("checkout runs...");
    debugPrint(clientProfile.toJSON());
    debugPrint(shippingData.toJSON());
  }

  late Future<Product> futureProduct;

  @override
  void initState() {
    super.initState();
    futureProduct = fetchProduct(productIndex: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: FutureBuilder<Product>(
        future: futureProduct,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Column(children: [
              Text('${snapshot.data!.productName} '),
              Image.network(snapshot.data!.productFirstImage),
              ElevatedButton(
                  onPressed: runSimulateCart,
                  child: const Text('Simulate Cart')),
              ElevatedButton(
                  onPressed: runCheckout, child: const Text('Checkout')),
            ]);
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }
          //
          return const CircularProgressIndicator();
        },
      )),
    );
  }
}
