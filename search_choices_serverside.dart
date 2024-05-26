import 'dart:convert';

import 'package:search_choices_app/model/company_list.dart';
import 'package:search_choices_app/utils/config.dart';
import 'package:search_choices_app/utils/helper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:search_choices/search_choices.dart';

class SearchChoicesServerSideSearch extends StatefulWidget {
  const SearchChoicesServerSideSearch({Key? key}) : super(key: key);

  @override
  _SearchChoicesServerSideSearchState createState() =>
      _SearchChoicesServerSideSearchState();
}

class _SearchChoicesServerSideSearchState
    extends State<SearchChoicesServerSideSearch> {
  TextEditingController controller1 = TextEditingController();
  int? id;
  Tuple2<int, String>? selectedValue;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            body: SafeArea(
                child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SearchChoices.single(
          value: selectedValue, // should pass here Tuple2<int,String>
          hint: "Search Company",
          onChanged: (newValue) {
            setIdAndPartyName(newValue);
            print('You will get object here $newValue');
          },
          selectedValueWidgetFn: (Tuple2<int, String> selectedItem) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                selectedItem.item2,
                style: TextStyle(color: Colors.black),
              ),
            );
          },
          displayClearIcon: true,
          futureSearchFn: futureSearchFnPartyNames,
        ),
      ),
    ))));
  }

  void setIdAndPartyName(dynamic? value) {
    print("value $value");
    if (value != null) {
      setState(() {
        selectedValue = value;
        controller1.text = value.item2;
        id = value.item1;
      });
    }
  }

  Future<List<Tuple2<int, String>>> fetchFilterDataFromApi(
      String pattern) async {
    try {
      // get your access token here which you will store in SharedPreferences while doing login
      String accessToken = await getToken();
      List<Tuple2<int, String>> partyData = [];

      List<String> partyType = ['Company', 'Buyer'];
      String query = partyType.join(',');

      Map<String, String> queryParams = {};

      if (pattern.isNotEmpty) {
        queryParams['party_name__istartswith'] = pattern;
      } else {
        queryParams['count'] = '30';
      }
// your url here
      Uri url =
          Uri.parse('').replace(
        queryParameters: {
          'party_type__in': query,
          'is_active': 'true',
        }..addAll(queryParams),
      );

      http.Response response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        CompanyModel companyModel = CompanyModel.fromJson(jsonResponse);

        if (companyModel.results != null) {
          partyData = companyModel.results!
              .map((e) => Tuple2(e.id ?? 0, e.partyName ?? ''))
              .toList();
          return partyData;
        } else {
          print('Error: CompanyModel results are null');
          return [];
        }
      } else {
        print('Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching data: $e');
      return [];
    }
  }

  Future<Tuple2<List<DropdownMenuItem<Tuple2<int, String>>>, int>>
      fetchDropdownItems(
    String? keyword,
    String? orderBy,
    bool? orderAsc,
    List<Tuple2<String, String>>? filters,
    int? pageNb,
  ) async {
    List<Tuple2<int, String>> partyData =
        await fetchFilterDataFromApi(keyword ?? '');
    List<DropdownMenuItem<Tuple2<int, String>>> dropdownItems = partyData
        .map<DropdownMenuItem<Tuple2<int, String>>>(
          (item) => DropdownMenuItem<Tuple2<int, String>>(
            value: item, // Passing the entire Tuple2 object
            child: Text(item.item2),
          ),
        )
        .toList();

    int nbResults = partyData.length;
    return Tuple2<List<DropdownMenuItem<Tuple2<int, String>>>, int>(
      dropdownItems,
      nbResults,
    );
  }

  Future<Tuple2<List<DropdownMenuItem<Tuple2<int, String>>>, int>>
      futureSearchFnPartyNames(
    String? keyword,
    String? orderBy,
    bool? orderAsc,
    List<Tuple2<String, String>>? filters,
    int? pageNb,
  ) async {
    print(
        "keyword $keyword orderBy $orderBy orderAsc $orderAsc filters $filters page number $pageNb");
    return fetchDropdownItems(keyword, orderBy, orderAsc, filters, pageNb);
  }
}
