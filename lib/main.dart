import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

void main() => runApp(const SanCanApp());

class SanCanApp extends StatelessWidget {
  const SanCanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '三餐',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F4E9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA8C9A3),
          primary: const Color(0xFFA8C9A3),
          secondary: const Color(0xFFF2D398),
          surface: const Color(0xFFFFFBF3),
          onPrimary: Colors.white,
          onSecondary: const Color(0xFF4A3F35),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F4E9),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF4A3F35),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Color(0xFF6B9F6A)),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFFFFFBF3),
          elevation: 2,
          shadowColor: const Color(0xFFA8C9A3).withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFA8C9A3),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6B9F6A),
            side: const BorderSide(color: Color(0xFFA8C9A3)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFBF3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDD6C8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDD6C8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFA8C9A3)),
          ),
          labelStyle: const TextStyle(color: Color(0xFF6B9F6A)),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF4A3F35)),
          bodyMedium: TextStyle(color: Color(0xFF4A3F35)),
          titleMedium: TextStyle(color: Color(0xFF4A3F35), fontWeight: FontWeight.w600),
        ),
      ),
      home: const HomePage(),
    );
  }
}

// 食材模型
class FoodItem {
  String id;
  String name;
  double pricePerJin;
  double kcal;
  double protein;
  double fat;
  double carb;
  String category;

  FoodItem({
    required this.id,
    required this.name,
    required this.pricePerJin,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carb,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'pricePerJin': pricePerJin,
    'kcal': kcal, 'protein': protein, 'fat': fat, 'carb': carb, 'category': category
  };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
    id: json['id'], name: json['name'], pricePerJin: json['pricePerJin'].toDouble(),
    kcal: json['kcal'].toDouble(), protein: json['protein'].toDouble(),
    fat: json['fat'].toDouble(), carb: json['carb'].toDouble(), category: json['category']
  );
}

// 菜谱用料
class RecipeMat {
  String foodId;
  double weightGram;
  RecipeMat({required this.foodId, required this.weightGram});

  Map<String, dynamic> toJson() => {'foodId': foodId, 'weightGram': weightGram};
  factory RecipeMat.fromJson(Map<String, dynamic> json) =>
      RecipeMat(foodId: json['foodId'], weightGram: json['weightGram'].toDouble());
}

// 菜谱模型
class Recipe {
  String id;
  String title;
  List<RecipeMat> materials;
  String mealType;
  String cuisine;
  List<String> steps;

  Recipe({
    required this.id,
    required this.title,
    required this.materials,
    this.mealType = '通用',
    required this.cuisine,
    required this.steps,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title,
    'materials': materials.map((e) => e.toJson()).toList(),
    'mealType': mealType, 'cuisine': cuisine, 'steps': steps
  };

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
    id: json['id'], title: json['title'],
    materials: (json['materials'] as List).map((e) => RecipeMat.fromJson(e)).toList(),
    mealType: json['mealType'] ?? '通用',
    cuisine: json['cuisine'] ?? '其他',
    steps: (json['steps'] as List).cast<String>(),
  );

  double calcCost(List<FoodItem> foods) {
    double total = 0;
    for (var m in materials) {
      final f = foods.where((e) => e.id == m.foodId).firstOrNull;
      if (f != null) total += f.pricePerJin * (m.weightGram / 500);
    }
    return total;
  }

  Map<String, double> calcNutri(List<FoodItem> foods) {
    double k = 0, p = 0, f = 0, c = 0;
    for (var m in materials) {
      final food = foods.where((e) => e.id == m.foodId).firstOrNull;
      if (food != null) {
        double rate = m.weightGram / 100;
        k += food.kcal * rate;
        p += food.protein * rate;
        f += food.fat * rate;
        c += food.carb * rate;
      }
    }
    return {'kcal': k, 'protein': p, 'fat': f, 'carb': c};
  }

  bool hasDislike(List<String> dislikedIds) {
    return materials.any((m) => dislikedIds.contains(m.foodId));
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final uuid = const Uuid();
  List<FoodItem> foods = [];
  List<Recipe> recipes = [];
  List<String> dislikedFoodIds = [];
  double budget = 30.0;
  String selectedCuisine = '全部菜系';
  List<Recipe> todayMenu = [];
  final TextEditingController _budgetCtl = TextEditingController();
  final List<String> cuisineList = ['全部菜系', '川菜', '湘菜', '粤菜', '闽菜'];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final sp = await SharedPreferences.getInstance();
    final foodStr = sp.getString('foods');
    final recipeStr = sp.getString('recipes');
    final dislikeStr = sp.getString('dislikedIds');
    budget = sp.getDouble('budget') ?? 30.0;
    selectedCuisine = sp.getString('cuisine') ?? '全部菜系';
    _budgetCtl.text = budget.toStringAsFixed(0);

    if (foodStr == null) {
      foods = [
        FoodItem(id: uuid.v4(), name: '后腿猪肉', pricePerJin: 9.9, kcal: 143, protein: 20.3, fat: 6.2, carb: 1.5, category: '肉蛋'),
        FoodItem(id: uuid.v4(), name: '前腿猪肉', pricePerJin: 11.5, kcal: 155, protein: 19.5, fat: 8.5, carb: 1.2, category: '肉蛋'),
        FoodItem(id: uuid.v4(), name: '鸡胸肉', pricePerJin: 12.0, kcal: 133, protein: 24.6, fat: 3.2, carb: 0, category: '肉蛋'),
        FoodItem(id: uuid.v4(), name: '鸡蛋', pricePerJin: 5.8, kcal: 143, protein: 13.3, fat: 8.8, carb: 2.8, category: '肉蛋'),
        FoodItem(id: uuid.v4(), name: '土豆', pricePerJin: 2.0, kcal: 77, protein: 2.0, fat: 0.1, carb: 17.2, category: '蔬菜'),
        FoodItem(id: uuid.v4(), name: '大白菜', pricePerJin: 2.0, kcal: 17, protein: 1.5, fat: 0.2, carb: 3.2, category: '蔬菜'),
        FoodItem(id: uuid.v4(), name: '青椒', pricePerJin: 2.4, kcal: 25, protein: 1.0, fat: 0.2, carb: 5.4, category: '蔬菜'),
        FoodItem(id: uuid.v4(), name: '螺丝椒', pricePerJin: 3.5, kcal: 28, protein: 1.1, fat: 0.2, carb: 6.0, category: '蔬菜'),
        FoodItem(id: uuid.v4(), name: '番茄', pricePerJin: 3.5, kcal: 18, protein: 0.9, fat: 0.2, carb: 3.9, category: '蔬菜'),
        FoodItem(id: uuid.v4(), name: '黄瓜', pricePerJin: 2.4, kcal: 16, protein: 0.8, fat: 0.2, carb: 2.9, category: '蔬菜'),
        FoodItem(id: uuid.v4(), name: '菜心', pricePerJin: 3.8, kcal: 20, protein: 1.6, fat: 0.2, carb: 4.1, category: '蔬菜'),
        FoodItem(id: uuid.v4(), name: '空心菜', pricePerJin: 3.0, kcal: 19, protein: 2.2, fat: 0.3, carb: 3.6, category: '蔬菜'),
        FoodItem(id: uuid.v4(), name: '北豆腐', pricePerJin: 3.2, kcal: 85, protein: 12.2, fat: 4.8, carb: 2.0, category: '豆制品'),
        FoodItem(id: uuid.v4(), name: '大米', pricePerJin: 2.8, kcal: 345, protein: 7.4, fat: 0.8, carb: 77.9, category: '主食'),
        FoodItem(id: uuid.v4(), name: '苹果', pricePerJin: 5.5, kcal: 52, protein: 0.3, fat: 0.2, carb: 14.0, category: '水果'),
      ];
      saveFoods();
    } else {
      foods = (jsonDecode(foodStr) as List).map((e) => FoodItem.fromJson(e)).toList();
    }

    if (recipeStr == null) {
      final eggId = foods.firstWhere((e) => e.name == '鸡蛋').id;
      final tomatoId = foods.firstWhere((e) => e.name == '番茄').id;
      final porkId = foods.firstWhere((e) => e.name == '后腿猪肉').id;
      final greenPepperId = foods.firstWhere((e) => e.name == '青椒').id;
      final potatoId = foods.firstWhere((e) => e.name == '土豆').id;
      final riceId = foods.firstWhere((e) => e.name == '大米').id;
      final cabbageId = foods.firstWhere((e) => e.name == '大白菜').id;
      final cucumberId = foods.firstWhere((e) => e.name == '黄瓜').id;
      final screwPepperId = foods.firstWhere((e) => e.name == '螺丝椒').id;
      final frontPorkId = foods.firstWhere((e) => e.name == '前腿猪肉').id;
      final chickenId = foods.firstWhere((e) => e.name == '鸡胸肉').id;
      final cabbageHeartId = foods.firstWhere((e) => e.name == '菜心').id;
      final tofuId = foods.firstWhere((e) => e.name == '北豆腐').id;

      recipes = [
        Recipe(id: uuid.v4(), title: '番茄炒蛋', materials: [
          RecipeMat(foodId: tomatoId, weightGram: 300),
          RecipeMat(foodId: eggId, weightGram: 120),
        ], mealType: '午餐', cuisine: '川菜', steps: [
          '番茄洗净切块，鸡蛋打散加少许盐搅匀',
          '热锅倒油，倒入蛋液炒至凝固盛出',
          '锅中补少许油，放入番茄翻炒出汁',
          '倒入炒好的鸡蛋，加盐、糖调味，翻炒均匀即可出锅'
        ]),
        Recipe(id: uuid.v4(), title: '青椒肉丝', materials: [
          RecipeMat(foodId: greenPepperId, weightGram: 250),
          RecipeMat(foodId: porkId, weightGram: 150),
        ], mealType: '午餐', cuisine: '川菜', steps: [
          '猪肉切丝，加生抽、淀粉腌制10分钟',
          '青椒去籽切丝',
          '热锅倒油，滑炒肉丝至变色盛出',
          '锅中留底油，炒香青椒丝',
          '倒回肉丝，加盐、生抽调味，翻炒均匀即可'
        ]),
        Recipe(id: uuid.v4(), title: '酸辣土豆丝', materials: [
          RecipeMat(foodId: potatoId, weightGram: 350),
        ], mealType: '晚餐', cuisine: '川菜', steps: [
          '土豆去皮切细丝，用清水浸泡去淀粉',
          '锅中水烧开，土豆丝焯水30秒捞出过凉水',
          '热锅倒油，爆香蒜末、干辣椒',
          '倒入土豆丝大火快炒，加醋、盐调味',
          '翻炒均匀即可出锅'
        ]),
        Recipe(id: uuid.v4(), title: '辣椒炒肉', materials: [
          RecipeMat(foodId: screwPepperId, weightGram: 250),
          RecipeMat(foodId: frontPorkId, weightGram: 200),
        ], mealType: '午餐', cuisine: '湘菜', steps: [
          '前腿肉切片，螺丝椒滚刀切块',
          '干锅放入辣椒，小火煸软盛出',
          '热锅倒油，放入肉片煸炒出油',
          '加生抽、老抽调味上色',
          '倒入煸好的辣椒，加盐翻炒均匀即可'
        ]),
        Recipe(id: uuid.v4(), title: '白灼菜心', materials: [
          RecipeMat(foodId: cabbageHeartId, weightGram: 300),
        ], mealType: '晚餐', cuisine: '粤菜', steps: [
          '菜心洗净，切掉老根',
          '锅中水烧开，加少许盐和油',
          '放入菜心焯烫1-2分钟至断生',
          '捞出摆盘，淋上生抽，浇上热油即可'
        ]),
        Recipe(id: uuid.v4(), title: '香煎鸡胸肉', materials: [
          RecipeMat(foodId: chickenId, weightGram: 200),
        ], mealType: '午餐', cuisine: '粤菜', steps: [
          '鸡胸肉横切厚片，用刀背拍松',
          '加少许盐、黑胡椒腌制15分钟',
          '平底锅刷薄油，放入鸡胸肉',
          '中小火每面煎3-4分钟至熟透即可'
        ]),
        Recipe(id: uuid.v4(), title: '家常豆腐', materials: [
          RecipeMat(foodId: tofuId, weightGram: 300),
        ], mealType: '晚餐', cuisine: '闽菜', steps: [
          '北豆腐切厚块，用厨房纸吸干水分',
          '平底锅倒油，放入豆腐煎至两面金黄盛出',
          '锅中留底油，加蒜末、生抽、少许水调成料汁',
          '倒入豆腐，小火焖2分钟收汁即可'
        ]),
        Recipe(id: uuid.v4(), title: '拍黄瓜', materials: [
          RecipeMat(foodId: cucumberId, weightGram: 300),
        ], mealType: '晚餐', cuisine: '其他', steps: [
          '黄瓜洗净，用刀背拍碎切段',
          '加盐腌制10分钟，倒掉杀出的水分',
          '加蒜末、生抽、醋、少许糖拌匀',
          '淋上香油即可食用'
        ]),
        Recipe(id: uuid.v4(), title: '清炒大白菜', materials: [
          RecipeMat(foodId: cabbageId, weightGram: 350),
        ], mealType: '晚餐', cuisine: '其他', steps: [
          '大白菜洗净切段',
          '热锅倒油，爆香蒜末',
          '放入大白菜大火快炒',
          '加盐调味，炒至菜叶变软即可出锅'
        ]),
        Recipe(id: uuid.v4(), title: '白米饭', materials: [
          RecipeMat(foodId: riceId, weightGram: 200),
        ], mealType: '主食', cuisine: '其他', steps: [
          '大米淘洗2-3遍',
          '加入没过手指一节的清水',
          '放入电饭煲，按下煮饭键',
          '煮好后焖10分钟再开盖口感更好'
        ]),
      ];
      saveRecipes();
    } else {
      recipes = (jsonDecode(recipeStr) as List).map((e) => Recipe.fromJson(e)).toList();
    }

    if (dislikeStr != null) {
      dislikedFoodIds = (jsonDecode(dislikeStr) as List).cast<String>();
    }

    generateMenu();
    setState(() {});
  }

  Future<void> saveFoods() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('foods', jsonEncode(foods.map((e) => e.toJson()).toList()));
  }
  Future<void> saveRecipes() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('recipes', jsonEncode(recipes.map((e) => e.toJson()).toList()));
  }
  Future<void> saveBudget() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble('budget', budget);
  }
  Future<void> saveCuisine() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('cuisine', selectedCuisine);
  }
  Future<void> saveDislikes() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('dislikedIds', jsonEncode(dislikedFoodIds));
  }

  void generateMenu() {
    List<Recipe> pool = recipes.where((r) => !r.hasDislike(dislikedFoodIds)).toList();
    if (selectedCuisine != '全部菜系') {
      pool = pool.where((r) => r.cuisine == selectedCuisine || r.cuisine == '其他').toList();
    }
    pool.shuffle();
    List<Recipe> result = [];
    double cost = 0;
    bool hasMeat = false, hasVeg = false, hasStaple = false;

    for (var r in pool) {
      double c = r.calcCost(foods);
      if (cost + c > budget) continue;

      bool hasMeatDish = r.materials.any((m) {
        final f = foods.where((e) => e.id == m.foodId).firstOrNull;
        return f?.category == '肉蛋' || f?.category == '豆制品';
      });
      bool hasVegDish = r.materials.any((m) {
        final f = foods.where((e) => e.id == m.foodId).firstOrNull;
        return f?.category == '蔬菜';
      });
      bool isStaple = r.materials.any((m) {
        final f = foods.where((e) => e.id == m.foodId).firstOrNull;
        return f?.category == '主食';
      });

      if (isStaple && hasStaple) continue;
      result.add(r);
      cost += c;
      if (hasMeatDish) hasMeat = true;
      if (hasVegDish) hasVeg = true;
      if (isStaple) hasStaple = true;

      if (result.length >= 4 && hasMeat && hasVeg && hasStaple) break;
    }
    todayMenu = result;
  }

  void updateBudget(String value) {
    final val = double.tryParse(value);
    if (val != null && val > 0) {
      budget = val;
      saveBudget();
      generateMenu();
      setState(() {});
    }
  }

  // 买菜清单弹窗
  void _showShoppingList() {
    if (todayMenu.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无菜单，无法生成买菜清单')),
      );
      return;
    }

    Map<String, double> materialMap = {};
    for (var recipe in todayMenu) {
      for (var mat in recipe.materials) {
        if (materialMap.containsKey(mat.foodId)) {
          materialMap[mat.foodId] = materialMap[mat.foodId]! + mat.weightGram;
        } else {
          materialMap[mat.foodId] = mat.weightGram;
        }
      }
    }

    List<Map<String, dynamic>> shoppingList = [];
    double totalWeight = 0;
    double totalCost = 0;

    materialMap.forEach((foodId, weight) {
      final food = foods.where((e) => e.id == foodId).firstOrNull;
      if (food != null) {
        double cost = food.pricePerJin * (weight / 500);
        shoppingList.add({
          'name': food.name,
          'weightGram': weight,
          'weightJin': weight / 500,
          'cost': cost,
        });
        totalWeight += weight;
        totalCost += cost;
      }
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFFBF3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('今日买菜清单'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: shoppingList.length,
            itemBuilder: (ctx, i) {
              final item = shoppingList[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['name']),
                    Text(
                      '${item['weightGram'].toStringAsFixed(0)}g · ${item['weightJin'].toStringAsFixed(2)}斤',
                      style: const TextStyle(color: Color(0xFF6B9F6A)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('总重量'),
                    Text('${totalWeight.toStringAsFixed(0)}g · ${(totalWeight / 500).toStringAsFixed(2)}斤'),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('预计花费', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '¥${totalCost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B9F6A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  // 导出备份到手机下载目录
  Future<void> exportBackup() async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请授予存储权限')),
      );
      return;
    }

    final dir = await getExternalStorageDirectory();
    if (dir == null) return;

    final downloadDir = Directory('${dir.parent.parent.parent.parent.path}/Download');
    if (!await downloadDir.exists()) {
      await downloadDir.create();
    }

    final file = File('${downloadDir.path}/三餐备份_${DateTime.now().millisecondsSinceEpoch}.json');
    final data = {
      'foods': foods.map((e) => e.toJson()).toList(),
      'recipes': recipes.map((e) => e.toJson()).toList(),
      'budget': budget,
      'cuisine': selectedCuisine,
      'dislikedIds': dislikedFoodIds,
    };

    await file.writeAsString(jsonEncode(data));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('备份已保存：${file.path}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalCost = todayMenu.fold(0, (pre, r) => pre + r.calcCost(foods));
    Map<String, double> totalNutri = {'kcal': 0, 'protein': 0, 'fat': 0, 'carb': 0};
    for (var r in todayMenu) {
      final n = r.calcNutri(foods);
      totalNutri['kcal'] = totalNutri['kcal']! + n['kcal']!;
      totalNutri['protein'] = totalNutri['protein']! + n['protein']!;
      totalNutri['fat'] = totalNutri['fat']! + n['fat']!;
      totalNutri['carb'] = totalNutri['carb']! + n['carb']!;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('三餐')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 预算卡片
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('今天想吃多少钱的餐？', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _budgetCtl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            onChanged: updateBudget,
                            decoration: const InputDecoration(suffixText: '元'),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: budget.clamp(10, 100),
                      min: 10,
                      max: 100,
                      divisions: 18,
                      label: '${budget.round()}元',
                      activeColor: const Color(0xFFA8C9A3),
                      inactiveColor: const Color(0xFFDDD6C8),
                      onChanged: (v) {
                        budget = v;
                        _budgetCtl.text = budget.toStringAsFixed(0);
                        saveBudget();
                        generateMenu();
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text('菜系偏好：', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: cuisineList.map((c) {
                        bool isSelected = selectedCuisine == c;
                        return GestureDetector(
                          onTap: () {
                            selectedCuisine = c;
                            saveCuisine();
                            generateMenu();
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFA8C9A3) : const Color(0xFFF0EADD),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              c,
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF4A3F35),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 今日菜单卡片
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('今日推荐菜单', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (todayMenu.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('当前预算或忌口条件下暂无合适菜品，请调整预算或减少忌口食材。',
                            style: TextStyle(color: Colors.grey)),
                      )
                    else
                      ...todayMenu.map((r) => InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => RecipeDetailPage(recipe: r, foods: foods),
                        )),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(r.title, style: const TextStyle(fontSize: 15)),
                              Row(
                                children: [
                                  Text(
                                    '¥${r.calcCost(foods).toStringAsFixed(2)}',
                                    style: const TextStyle(color: Color(0xFF6B9F6A), fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('今日合计', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          '¥${totalCost.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, color: Color(0xFF6B9F6A), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _showShoppingList,
                        child: const Text('查看买菜清单'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 营养卡片
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('全天营养估算', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text('热量：${totalNutri['kcal']!.toStringAsFixed(0)} kcal'),
                    Text('蛋白质：${totalNutri['protein']!.toStringAsFixed(1)} g'),
                    Text('脂肪：${totalNutri['fat']!.toStringAsFixed(1)} g'),
                    Text('碳水：${totalNutri['carb']!.toStringAsFixed(1)} g'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 功能按钮网格
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                FilledButton(
                  onPressed: () { setState(() { generateMenu(); }); },
                  child: const Text('换一批'),
                ),
                FilledButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => FoodManagePage(foods: foods, onSave: () { saveFoods(); generateMenu(); setState(() {}); }),
                  )),
                  child: const Text('食材价格'),
                ),
                FilledButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => RecipeManagePage(recipes: recipes, foods: foods, onSave: () { saveRecipes(); generateMenu(); setState(() {}); }),
                  )),
                  child: const Text('菜谱管理'),
                ),
                FilledButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => DislikeManagePage(
                      foods: foods,
                      dislikedIds: dislikedFoodIds,
                      onSave: () { saveDislikes(); generateMenu(); setState(() {}); },
                    ),
                  )),
                  child: const Text('忌口管理'),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Center(
              child: OutlinedButton(onPressed: exportBackup, child: const Text('导出数据备份')),
            ),
          ],
        ),
      ),
    );
  }
}

// 菜谱详情页
class RecipeDetailPage extends StatelessWidget {
  final Recipe recipe;
  final List<FoodItem> foods;
  const RecipeDetailPage({super.key, required this.recipe, required this.foods});

  @override
  Widget build(BuildContext context) {
    final nutri = recipe.calcNutri(foods);
    return Scaffold(
      appBar: AppBar(title: Text(recipe.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${recipe.cuisine} · ${recipe.mealType}', style: const TextStyle(color: Color(0xFF6B9F6A), fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('成本：¥${recipe.calcCost(foods).toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text('食材用量', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...recipe.materials.map((m) {
                      final food = foods.where((e) => e.id == m.foodId).firstOrNull;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(food?.name ?? '未知食材'),
                            Text('${m.weightGram.toStringAsFixed(0)} g'),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    const Text('营养信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('热量：${nutri['kcal']!.toStringAsFixed(0)} kcal | 蛋白质：${nutri['protein']!.toStringAsFixed(1)} g'),
                    Text('脂肪：${nutri['fat']!.toStringAsFixed(1)} g | 碳水：${nutri['carb']!.toStringAsFixed(1)} g'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('做法步骤', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...recipe.steps.asMap().entries.map((entry) {
                      int idx = entry.key + 1;
                      String step = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Color(0xFFA8C9A3),
                                shape: BoxShape.circle,
                              ),
                              child: Text('$idx', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(step)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 食材价格管理页面
class FoodManagePage extends StatefulWidget {
  final List<FoodItem> foods;
  final Function onSave;
  const FoodManagePage({super.key, required this.foods, required this.onSave});

  @override
  State<FoodManagePage> createState() => _FoodManagePageState();
}

class _FoodManagePageState extends State<FoodManagePage> {
  final uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('食材价格管理')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.foods.length,
        itemBuilder: (ctx, i) {
          final f = widget.foods[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text('${f.name}（${f.category}）'),
              subtitle: Text('单价：${f.pricePerJin} 元/斤 · 热量：${f.kcal} kcal/100g'),
              trailing: IconButton(icon: const Icon(Icons.edit, color: Color(0xFF6B9F6A)), onPressed: () => editFood(i)),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFA8C9A3),
        foregroundColor: Colors.white,
        onPressed: addFood,
        child: const Icon(Icons.add),
      ),
    );
  }

  void editFood(int index) {
    final f = widget.foods[index];
    final ctl = TextEditingController(text: f.pricePerJin.toString());
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFFFFFBF3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('修改 ${f.name} 单价'),
      content: TextField(
        controller: ctl,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: '元/斤'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        TextButton(onPressed: () {
          final v = double.tryParse(ctl.text);
          if (v != null) {
            widget.foods[index].pricePerJin = v;
            widget.onSave();
            setState(() {});
            Navigator.pop(ctx);
          }
        }, child: const Text('保存')),
      ],
    ));
  }

  void addFood() {
    final nameCtl = TextEditingController();
    final priceCtl = TextEditingController();
    String category = '蔬菜';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: const Color(0xFFFFFBF3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('新增食材'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtl, decoration: const InputDecoration(labelText: '食材名称')),
          TextField(controller: priceCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '单价（元/斤）')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: category,
            decoration: const InputDecoration(labelText: '分类'),
            items: const [
              DropdownMenuItem(value: '蔬菜', child: Text('蔬菜')),
              DropdownMenuItem(value: '水果', child: Text('水果')),
              DropdownMenuItem(value: '肉蛋', child: Text('肉蛋')),
              DropdownMenuItem(value: '主食', child: Text('主食')),
              DropdownMenuItem(value: '豆制品', child: Text('豆制品')),
            ],
            onChanged: (v) { if (v != null) setDialogState(() => category = v); },
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(onPressed: () {
            final p = double.tryParse(priceCtl.text);
            if (nameCtl.text.isNotEmpty && p != null) {
              widget.foods.add(FoodItem(
                id: uuid.v4(), name: nameCtl.text, pricePerJin: p,
                kcal: 0, protein: 0, fat: 0, carb: 0, category: category,
              ));
              widget.onSave();
              setState(() {});
              Navigator.pop(ctx);
            }
          }, child: const Text('添加')),
        ],
      ),
    ));
  }
}

// 菜谱管理页面
class RecipeManagePage extends StatefulWidget {
  final List<Recipe> recipes;
  final List<FoodItem> foods;
  final Function onSave;
  const RecipeManagePage({super.key, required this.recipes, required this.foods, required this.onSave});

  @override
  State<RecipeManagePage> createState() => _RecipeManagePageState();
}

class _RecipeManagePageState extends State<RecipeManagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('菜谱管理')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.recipes.length,
        itemBuilder: (ctx, i) {
          final r = widget.recipes[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(r.title),
              subtitle: Text('${r.cuisine} · 成本：¥${r.calcCost(widget.foods).toStringAsFixed(2)} · ${r.mealType}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () {
                  widget.recipes.removeAt(i);
                  widget.onSave();
                  setState(() {});
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// 忌口管理页面
class DislikeManagePage extends StatefulWidget {
  final List<FoodItem> foods;
  final List<String> dislikedIds;
  final Function onSave;
  const DislikeManagePage({super.key, required this.foods, required this.dislikedIds, required this.onSave});

  @override
  State<DislikeManagePage> createState() => _DislikeManagePageState();
}

class _DislikeManagePageState extends State<DislikeManagePage> {
  late List<String> localIds;

  @override
  void initState() {
    super.initState();
    localIds = List.from(widget.dislikedIds);
  }

  void toggleDislike(String id) {
    if (localIds.contains(id)) {
      localIds.remove(id);
    } else {
      localIds.add(id);
    }
    widget.dislikedIds.clear();
    widget.dislikedIds.addAll(localIds);
    widget.onSave();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['蔬菜', '水果', '肉蛋', '主食', '豆制品'];
    return Scaffold(
      appBar: AppBar(title: const Text('忌口食材管理')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: categories.map((cat) {
          final list = widget.foods.where((f) => f.category == cat).toList();
          if (list.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                child: Text(cat, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6B9F6A))),
              ),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: list.map((f) => CheckboxListTile(
                    title: Text(f.name),
                    value: localIds.contains(f.id),
                    onChanged: (_) => toggleDislike(f.id),
                    activeColor: const Color(0xFFA8C9A3),
                    controlAffinity: ListTileControlAffinity.leading,
                  )).toList(),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}