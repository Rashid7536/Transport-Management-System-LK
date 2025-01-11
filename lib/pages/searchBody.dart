import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:leaflet_test/database.dart';
// import '../../test/mapBody.dart';

class SearchBody extends StatefulWidget {
  final BuildContext modalContext; // Add this to hold the modal context

  const SearchBody(
      {super.key,
      required this.modalContext}); // Update the constructor to require modalContext

  @override
  State<SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<SearchBody> {
  
  final DatabaseReference fdb = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> allDataS = [];
  List<Map<String, dynamic>> filteredDataS = [];
  bool isLoadingS = true;
  TextEditingController searchControllerS = TextEditingController();

  @override
  void initState() {
    fetchDataS();
    searchControllerS.addListener(() {
      filterDataS(searchControllerS.text);
    });
    super.initState();
  }

  Future<void> fetchDataS() async {
    DataSnapshot dataSnapshot = await fdb.child('formatted_Bus').get();

    final data = dataSnapshot.value as List<dynamic>;
    List<Map<String, dynamic>> results = [];
    
    data.forEach((busStand) {
      results.add({
        'Name': busStand['Name'],
        'Longitude': busStand['Longitude'],
        'Latitude': busStand['Latitude'],
      });
    });

    setState(() {
      allDataS = results;
      filteredDataS = results;
      isLoadingS = false;
    });
  }

  void filterDataS(String query) {
    List<Map<String, dynamic>> results = [];
    if (query.isEmpty) {
      results = allDataS;
    } else {
      results = allDataS
          .where((busStand) => busStand['Name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    }

    setState(() {
      filteredDataS = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search'), automaticallyImplyLeading: false),
      body: Center(
        child: Column(
          children: [
            Padding(padding: EdgeInsets.all(5)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 300,
                  child: TextField(
                    keyboardType: TextInputType.text,
                    controller: searchControllerS,
                    decoration: InputDecoration(
                      filled: true,
                      labelText: "Search",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    filterDataS(searchControllerS.text);
                  },
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
            Padding(padding: EdgeInsets.all(5)),
            Expanded(
              child: isLoadingS
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.builder(
                      itemCount: filteredDataS.length,
                      itemBuilder: (context, index) {
                        final busStand = filteredDataS[index];
                        return InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Selected Bus Stand'),
                                actions: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(busStand['Name']),
                                        Padding(padding: EdgeInsets.all(10)),
                                        ElevatedButton(
                                          onPressed: () {
                                            print(busStand);
                                            Navigator.pop(context);
                                          },
                                          child: Text('Show On Map'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                            Navigator.pop(widget.modalContext,
                                busStand); // Use the modal's context
                          },
                          child: Card(
                            child: Column(
                              children: [
                                Text(''),
                                Text(busStand['Name']),
                                Text(''),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
