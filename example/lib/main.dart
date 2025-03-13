import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_place/google_place.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late GooglePlace googlePlace;
  List<AutocompletePrediction> predictions = [];

  @override
  void initState() {
    String apiKey = dotenv.env['API_KEY']!;
    googlePlace = GooglePlace(apiKey);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(right: 20, left: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                decoration: InputDecoration(
                  labelText: "Search",
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.blue,
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.black54,
                      width: 2.0,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    autoCompleteSearch(value);
                  } else {
                    if (predictions.isNotEmpty && mounted) {
                      setState(() {
                        predictions = [];
                      });
                    }
                  }
                },
              ),
              const SizedBox(
                height: 10,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: predictions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(
                          Icons.pin_drop,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(predictions[index].description ?? ''),
                      onTap: () {
                        final placeId = predictions[index].placeId;
                        if (placeId != null) {
                          debugPrint(placeId);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailsPage(
                                placeId: placeId,
                                googlePlace: googlePlace,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 10),
                child: Image.asset("assets/powered_by_google.png"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void autoCompleteSearch(String value) async {
    var result = await googlePlace.autocomplete.get(value);
    if (result != null && result.predictions != null && mounted) {
      setState(() {
        predictions = result.predictions!;
      });
    }
  }
}

class DetailsPage extends StatefulWidget {
  final String placeId;
  final GooglePlace googlePlace;

  const DetailsPage({
    Key? key,
    required this.placeId,
    required this.googlePlace,
  }) : super(key: key);

  @override
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  late DetailsResult? detailsResult;
  List<Uint8List> images = [];

  @override
  void initState() {
    detailsResult = null;
    getDetails(widget.placeId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Details"),
        backgroundColor: Colors.blueAccent,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () {
          getDetails(widget.placeId);
        },
        child: const Icon(Icons.refresh),
      ),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(right: 20, left: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 250,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.memory(
                            images[index],
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListView(
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.only(left: 15, top: 10),
                        child: const Text(
                          "Details",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (detailsResult?.types != null)
                        Container(
                          margin: const EdgeInsets.only(left: 15, top: 10),
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: detailsResult!.types!.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(right: 10),
                                child: Chip(
                                  label: Text(
                                    detailsResult!.types![index],
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: Colors.blueAccent,
                                ),
                              );
                            },
                          ),
                        ),
                      Container(
                        margin: const EdgeInsets.only(left: 15, top: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.location_on),
                          ),
                          title: Text(
                            detailsResult?.formattedAddress != null
                                ? 'Address: ${detailsResult!.formattedAddress}'
                                : "Address: Not available",
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 15, top: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.location_searching),
                          ),
                          title: Text(
                            detailsResult?.geometry?.location != null
                                ? 'Geometry: ${detailsResult!.geometry!.location!.lat},${detailsResult!.geometry!.location!.lng}'
                                : "Geometry: Not available",
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 15, top: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.timelapse),
                          ),
                          title: Text(
                            detailsResult?.utcOffset != null
                                ? 'UTC offset: ${detailsResult!.utcOffset} min'
                                : "UTC offset: Not available",
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 15, top: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.rate_review),
                          ),
                          title: Text(
                            detailsResult?.rating != null
                                ? 'Rating: ${detailsResult!.rating}'
                                : "Rating: Not available",
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 15, top: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.attach_money),
                          ),
                          title: Text(
                            detailsResult?.priceLevel != null
                                ? 'Price level: ${detailsResult!.priceLevel}'
                                : "Price level: Not available",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 20, bottom: 10),
                child: Image.asset("assets/powered_by_google.png"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void getDetails(String placeId) async {
    var result = await widget.googlePlace.details.get(placeId);
    if (result != null && result.result != null && mounted) {
      setState(() {
        detailsResult = result.result;
        images = [];
      });

      if (result.result?.photos != null) {
        for (var photo in result.result!.photos!) {
          if (photo.photoReference != null) {
            getPhoto(photo.photoReference!);
          }
        }
      }
    }
  }

  void getPhoto(String photoReference) async {
    var result = await widget.googlePlace.photos.get(photoReference, 0, 400);
    if (result != null && mounted) {
      setState(() {
        images.add(result);
      });
    }
  }
}
