# 快速参考指南

> 常用代码模式和 API 速查表

## 📑 目录

- [Provider 使用](#provider-使用)
- [路由导航](#路由导航)
- [状态管理](#状态管理)
- [异步操作](#异步操作)
- [UI 组件](#ui-组件)
- [常用工具](#常用工具)

---

## Provider 使用

### 读取 Provider

```dart
// 1. 监听变化 (自动重建)
final authState = ref.watch(authStateProvider);

// 2. 只读取一次 (不监听)
final authState = ref.read(authStateProvider);

// 3. 监听并执行副作用
ref.listen(authStateProvider, (previous, next) {
  if (next.credentials != null) {
    context.go('/home');
  }
});
```

### 修改 Provider

```dart
// StateProvider
ref.read(counterProvider.notifier).state = 10;

// StateNotifierProvider
ref.read(authStateProvider.notifier).login(username, password);
```

### 常用 Providers

```dart
// 认证状态
final authState = ref.watch(authStateProvider);

// 会话状态
final sessionState = ref.watch(sessionStateProvider);

// 当前会话
final currentSession = ref.watch(currentSessionProvider);

// 设置状态
final settings = ref.watch(settingsStateProvider);
```

---

## 路由导航

### 基本导航

```dart
// 跳转到新页面 (替换当前路由)
context.go('/session/123');

// 压入新页面 (保留当前路由)
context.push('/session/123');

// 返回上一页
context.pop();

// 返回并传递数据
context.pop(result);
```

### 命名路由

```dart
// 跳转到命名路由
context.goNamed(
  AppRoutes.sessionByIdName,
  pathParameters: {'id': sessionId},
  queryParameters: {'tab': 'messages'},
);

// 压入命名路由
context.pushNamed(
  AppRoutes.sessionInfoName,
  pathParameters: {'id': sessionId},
);
```

### 路由守卫

```dart
// 在 GoRouter 中配置
redirect: (context, state) {
  final isAuthenticated = ref.read(isAuthenticatedProvider);
  
  if (!isAuthenticated && state.location != '/login') {
    return '/login';
  }
  
  return null; // 不重定向
}
```

---

## 状态管理

### StatefulWidget

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  int _counter = 0;
  
  void _increment() {
    setState(() {
      _counter++;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Text('Count: $_counter');
  }
}
```

### ValueNotifier

```dart
// 定义
final _counterN = ValueNotifier<int>(0);

// 使用
ValueListenableBuilder<int>(
  valueListenable: _counterN,
  builder: (context, count, child) {
    return Text('Count: $count');
  },
)

// 修改
_counterN.value++;

// 释放
@override
void dispose() {
  _counterN.dispose();
  super.dispose();
}
```

### StreamBuilder

```dart
StreamBuilder<int>(
  stream: counterStream,
  initialData: 0,
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    
    if (!snapshot.hasData) {
      return CircularProgressIndicator();
    }
    
    return Text('Count: ${snapshot.data}');
  },
)
```

---

## 异步操作

### Future

```dart
// 定义异步函数
Future<String> fetchData() async {
  final response = await http.get(url);
  return response.body;
}

// 调用
void loadData() async {
  try {
    final data = await fetchData();
    print(data);
  } catch (error) {
    print('Error: $error');
  }
}

// 并行执行
final results = await Future.wait([
  fetchData1(),
  fetchData2(),
  fetchData3(),
]);
```

### Stream

```dart
// 创建 Stream
Stream<int> countStream() async* {
  for (int i = 0; i < 10; i++) {
    await Future.delayed(Duration(seconds: 1));
    yield i;
  }
}

// 监听 Stream
final subscription = stream.listen(
  (data) => print(data),
  onError: (error) => print('Error: $error'),
  onDone: () => print('Done'),
);

// 取消订阅
subscription.cancel();
```

### FutureBuilder

```dart
FutureBuilder<String>(
  future: fetchData(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    
    return Text('Data: ${snapshot.data}');
  },
)
```

---

## UI 组件

### 布局

```dart
// 垂直布局
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('Title'),
    Text('Subtitle'),
  ],
)

// 水平布局
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Icon(Icons.star),
    Text('Rating'),
  ],
)

// 堆叠布局
Stack(
  children: [
    Image.network(url),
    Positioned(
      bottom: 10,
      right: 10,
      child: Text('Overlay'),
    ),
  ],
)

// 弹性布局
Expanded(
  flex: 2,
  child: Container(color: Colors.red),
)
```

### 列表

```dart
// 固定列表
ListView(
  children: [
    ListTile(title: Text('Item 1')),
    ListTile(title: Text('Item 2')),
  ],
)

// 动态列表 (推荐)
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(title: Text(items[index]));
  },
)

// 分隔符列表
ListView.separated(
  itemCount: items.length,
  itemBuilder: (context, index) => ListTile(title: Text(items[index])),
  separatorBuilder: (context, index) => Divider(),
)
```

### 输入

```dart
// 文本输入
TextField(
  controller: _controller,
  decoration: InputDecoration(
    labelText: 'Username',
    hintText: 'Enter your username',
    prefixIcon: Icon(Icons.person),
  ),
  onChanged: (value) => print(value),
  onSubmitted: (value) => _handleSubmit(value),
)

// 多行输入
TextField(
  maxLines: 5,
  minLines: 3,
)

// 密码输入
TextField(
  obscureText: true,
  decoration: InputDecoration(
    labelText: 'Password',
  ),
)
```

### 按钮

```dart
// 文本按钮
TextButton(
  onPressed: () => print('Pressed'),
  child: Text('Click Me'),
)

// 填充按钮
ElevatedButton(
  onPressed: () => print('Pressed'),
  child: Text('Submit'),
)

// 轮廓按钮
OutlinedButton(
  onPressed: () => print('Pressed'),
  child: Text('Cancel'),
)

// 图标按钮
IconButton(
  icon: Icon(Icons.favorite),
  onPressed: () => print('Pressed'),
)

// 浮动按钮
FloatingActionButton(
  onPressed: () => print('Pressed'),
  child: Icon(Icons.add),
)
```

### 对话框

```dart
// 显示对话框
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Confirm'),
    content: Text('Are you sure?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text('Cancel'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text('OK'),
      ),
    ],
  ),
);

// 底部弹窗
showModalBottomSheet(
  context: context,
  builder: (context) => Container(
    height: 200,
    child: Center(child: Text('Bottom Sheet')),
  ),
);

// SnackBar
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Message sent'),
    action: SnackBarAction(
      label: 'Undo',
      onPressed: () => print('Undo'),
    ),
  ),
);
```

---

## 常用工具

### 日志

```dart
// 使用 Logger 扩展
Logger.info('Info message');
Logger.error('Error message');
Logger.debug('Debug message');

// 使用 print (开发环境)
print('Debug: $value');

// 使用 debugPrint (推荐)
debugPrint('Debug: $value');
```

### 时间处理

```dart
// 当前时间
final now = DateTime.now();

// 格式化时间
final formatted = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

// 时间比较
final isAfter = date1.isAfter(date2);
final isBefore = date1.isBefore(date2);

// 时间计算
final tomorrow = now.add(Duration(days: 1));
final yesterday = now.subtract(Duration(days: 1));
```

### 字符串处理

```dart
// 判空
if (str.isEmpty) { }
if (str.isNotEmpty) { }

// 去空格
final trimmed = str.trim();

// 分割
final parts = str.split(',');

// 替换
final replaced = str.replaceAll('old', 'new');

// 包含
if (str.contains('keyword')) { }

// 大小写
final upper = str.toUpperCase();
final lower = str.toLowerCase();
```

### 集合操作

```dart
// List
final list = [1, 2, 3];
list.add(4);
list.remove(2);
list.clear();

// Map
final map = {'key': 'value'};
map['newKey'] = 'newValue';
map.remove('key');
map.containsKey('key');

// Set
final set = {1, 2, 3};
set.add(4);
set.remove(2);
set.contains(3);

// 遍历
list.forEach((item) => print(item));
map.forEach((key, value) => print('$key: $value'));

// 转换
final doubled = list.map((x) => x * 2).toList();
final filtered = list.where((x) => x > 2).toList();
final sum = list.reduce((a, b) => a + b);
```

### 空安全

```dart
// 可空类型
String? nullableString;

// 非空断言 (确定不为 null)
final length = nullableString!.length;

// 空值检查
if (nullableString != null) {
  print(nullableString.length);
}

// 空值合并
final value = nullableString ?? 'default';

// 条件访问
final length = nullableString?.length;

// 级联空值检查
final length = nullableString?.trim()?.length;
```

### 错误处理

```dart
// try-catch
try {
  final result = await riskyOperation();
  print(result);
} catch (error) {
  print('Error: $error');
} finally {
  print('Cleanup');
}

// 特定异常
try {
  // ...
} on FormatException catch (e) {
  print('Format error: $e');
} on IOException catch (e) {
  print('IO error: $e');
} catch (e) {
  print('Unknown error: $e');
}

// 重新抛出
try {
  // ...
} catch (e) {
  print('Logging error: $e');
  rethrow;
}
```

---

## 生命周期

### StatefulWidget 生命周期

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  // 1. 创建 State 对象后立即调用
  @override
  void initState() {
    super.initState();
    print('initState');
  }
  
  // 2. 依赖变化时调用
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('didChangeDependencies');
  }
  
  // 3. Widget 配置变化时调用
  @override
  void didUpdateWidget(MyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('didUpdateWidget');
  }
  
  // 4. 构建 UI
  @override
  Widget build(BuildContext context) {
    print('build');
    return Container();
  }
  
  // 5. State 对象被移除时调用
  @override
  void dispose() {
    print('dispose');
    super.dispose();
  }
}
```

### 应用生命周期

```dart
class _MyWidgetState extends State<MyWidget> 
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        print('App resumed');
        break;
      case AppLifecycleState.inactive:
        print('App inactive');
        break;
      case AppLifecycleState.paused:
        print('App paused');
        break;
      case AppLifecycleState.detached:
        print('App detached');
        break;
    }
  }
}
```

---

## 性能优化

### const 构造函数

```dart
// ✅ 使用 const (不会重建)
const Text('Hello')
const SizedBox(height: 16)
const Icon(Icons.star)

// ❌ 不使用 const (每次都重建)
Text('Hello')
SizedBox(height: 16)
Icon(Icons.star)
```

### 提取不变的 Widget

```dart
// ❌ 不好的做法
Widget build(BuildContext context) {
  return Column(
    children: [
      Text('Title'),  // 每次都重建
      _buildContent(),
    ],
  );
}

// ✅ 好的做法
final _titleWidget = const Text('Title');

Widget build(BuildContext context) {
  return Column(
    children: [
      _titleWidget,  // 复用同一个实例
      _buildContent(),
    ],
  );
}
```

### 使用 ListView.builder

```dart
// ❌ 不好的做法 (一次性创建所有 Widget)
ListView(
  children: items.map((item) => ItemWidget(item)).toList(),
)

// ✅ 好的做法 (按需创建)
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

### 避免不必要的重建

```dart
// ✅ 使用 ValueListenableBuilder
ValueListenableBuilder<bool>(
  valueListenable: _isLoadingN,
  builder: (context, isLoading, child) {
    return isLoading 
      ? CircularProgressIndicator() 
      : child!;
  },
  child: ExpensiveWidget(),  // 不会重建
)

// ✅ 使用 RepaintBoundary
RepaintBoundary(
  child: ComplexWidget(),
)
```

---

## 调试技巧

### 打印 Widget 树

```dart
debugDumpApp();
```

### 打印渲染树

```dart
debugDumpRenderTree();
```

### 打印布局信息

```dart
debugPaintSizeEnabled = true;
```

### 检查 Widget 是否挂载

```dart
if (mounted) {
  setState(() { });
}
```

### 性能分析

```dart
// 在 DevTools 中查看
// - Performance 面板
// - Memory 面板
// - Network 面板
```

---

## 常用快捷键 (VS Code)

- `Ctrl + Space`: 代码补全
- `Ctrl + .`: 快速修复
- `F12`: 跳转到定义
- `Shift + F12`: 查找引用
- `Ctrl + Shift + R`: 重构
- `Ctrl + Shift + F`: 全局搜索
- `Ctrl + /`: 注释/取消注释

---

## 有用的命令

```bash
# 运行应用
flutter run

# 热重载
r

# 热重启
R

# 清理构建
flutter clean

# 获取依赖
flutter pub get

# 更新依赖
flutter pub upgrade

# 分析代码
flutter analyze

# 格式化代码
flutter format .

# 运行测试
flutter test

# 构建 APK
flutter build apk

# 构建 iOS
flutter build ios
```

---

## 相关文档

- [代码流程指南](./CODE_FLOW_GUIDE.md)
- [架构总览](./ARCHITECTURE_OVERVIEW.md)
- [Flutter 官方文档](https://flutter.dev/docs)
- [Riverpod 文档](https://riverpod.dev)
