//FirebaseFirestore とは、FlutterからFirestoreを操作するための入口
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
//firebase_auth はログイン・新規登録に使います。
//cloud_firestore はFirestoreにデータを保存するために使います。
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const WorkBoardApp());
  
}

//白いカードUIを作成　　ログイン画面などで使用
//StatelessWidget は、状態を持たない画面部品のこと
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
  });

  final Widget child;  //WidgetはFlutterの画面部品のこと
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: child, //child は、カードの中に入れる部品
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: card,
      ),
    );
  }
}


//TeamRoleを追加する
enum TeamRole {
  owner,
  admin,
  member,
  viewer,
}

//canCreateTaskを作る
bool canCreateTask(TeamRole role) {
  return role == TeamRole.owner ||
      role == TeamRole.admin ||
      role == TeamRole.member;
}

//canEditTaskを作る
bool canEditTask(TeamRole role) {
  return role == TeamRole.owner ||
      role == TeamRole.admin ||
      role == TeamRole.member;
}

//canDeleteTaskを作る
//削除は強い操作なので、owner と admin だけにします。
bool canDeleteTask(TeamRole role) {
  return role == TeamRole.owner || role == TeamRole.admin;
}



//Firestoreの文字列をTeamRoleに変換する
TeamRole teamRoleFromString(String? value) {
  switch (value) {
    case 'owner':
      return TeamRole.owner;
    case 'admin':
      return TeamRole.admin;
    case 'viewer':
      return TeamRole.viewer;
    case 'member':
    default:
      return TeamRole.member;
  }
}

//TeamRoleを日本語表示に変える
/*
String teamRoleLabel(TeamRole role) {
  switch (role) {
    case TeamRole.owner:
      return 'オーナー';
    case TeamRole.admin:
      return '管理者';
    case TeamRole.member:
      return 'メンバー';
    case TeamRole.viewer:
      return '閲覧者';
  }
}
*/

//医療機関向けにしたい場合です。
String teamRoleLabel(TeamRole role) {
  switch (role) {
    case TeamRole.owner:
      return '責任者';
    case TeamRole.admin:
      return '管理担当';
    case TeamRole.member:
      return '実務担当';
    case TeamRole.viewer:
      return '確認のみ';
  }
}


bool canCreateTaskByRole(TeamRole role) {
  return role == TeamRole.owner ||
      role == TeamRole.admin ||
      role == TeamRole.member;
}

bool canEditTaskByRole(TeamRole role) {
  return role == TeamRole.owner ||
      role == TeamRole.admin ||
      role == TeamRole.member;
}

bool canDeleteTaskByRole(TeamRole role) {
  return role == TeamRole.owner || role == TeamRole.admin;
}

bool canManageMembersByRole(TeamRole role) {
  return role == TeamRole.owner || role == TeamRole.admin;
}

bool canDeleteTeamByRole(TeamRole role) {
  return role == TeamRole.owner;
}

//これで、チーム1件分の見た目をまとめられます。
class TeamCard extends StatelessWidget {
  const TeamCard({
    super.key,
    required this.name,
    required this.onTap,
  });

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first : '?';

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.lineGreen,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.subText,
          ),
        ],
      ),
    );
  }
}

//TaskCard は、タスク1件分の見た目を作るWidget
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.assigneeEmail,
    required this.onTap,
  });

  final String title; //タスク名
  final String description; //タスク説明
  final String status; //未対応・進行中・完了.   Firestoreから取得した進行状況
  final String priority; //優先度  	Firestoreから取得した優先度
  final String assigneeEmail; //担当者メール
  final VoidCallback onTap;//タップしたときに動かす処理

  @override
  Widget build(BuildContext context) {
    return Align(
  alignment: Alignment.centerLeft,
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Label(text: statusLabel(status)),
                _Label(text: priorityLabel(priority)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.subText,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (assigneeEmail.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Text(
                  '担当：$assigneeEmail',
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  ),
);
  }

/*
//ここが大事
//status  todo未対応、doing進行中、done完了
  String statusLabel(String value) {
    switch (value) { //switch は、値によって返す文字を変える書き方
      case 'doing':
        return '進行中';
      case 'done':
        return '完了';
      case 'todo':
      default:
        return '未対応';
    }
  }
*/

//医療・院内業務向けならこうです。
String statusLabel(String value) {
  switch (value) {
    case 'doing':
      return '対応中';
    case 'done':
      return '対応済み';
    case 'todo':
    default:
      return '未対応';
  }
}


  String priorityLabel(String value) {
  switch (value) {
    case 'high':
      return '急ぎ';
    case 'low':
      return '余裕あり';
    case 'normal':
    default:
      return '通常';
  }
}

}

class _Label extends StatelessWidget {
  const _Label({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.subText,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

//入力欄を共通化 メールアドレスやパスワードを入力する場所
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;  //TextEditingController は、入力された文字を管理するための道具
  final String label;  //入力欄に表示する名前
  final bool obscureText;  //パスワードのように文字を隠す設定
  final TextInputType? keyboardType;  //メール入力用など、キーボードの種類を指定する設定
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: obscureText ? 1 : maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}


//エラー表示用の部品. ログイン失敗時など
class ErrorBox extends StatelessWidget {
  const ErrorBox({
    super.key,
    required this.message,  //表示するエラー文
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.22),  //AppColors.danger は、削除やエラーに使う赤色
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.danger,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }//alpha は、透明度のこと
}


// 1. アプリ全体の基盤となるクラス
class WorkBoardApp extends StatelessWidget {
  const WorkBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clinic Task Board',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.lineGreen,
          primary: AppColors.lineGreen,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.text,
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.white,
          titleTextStyle: TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.lineGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.lineGreen,
          foregroundColor: Colors.white,
          shape: CircleBorder(),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.lineGreen,
              width: 1.4,
            ),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 画面を返す
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingPage(message: 'ログイン状態を確認しています...');
        }

        final user = snapshot.data;

        if (user == null) { //データがない状態
          return const LoginPage(); //ログインしていない人に表示する画面
        }

        return const TeamListPage(); //ログイン済みの人に表示する画面
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

//新規登録画面
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}
//入力欄に入力された文字を取り出すための道具
class _RegisterPageState extends State<RegisterPage> {
  final displayNameController = TextEditingController();//名前
  final departmentController = TextEditingController();//所属
  //TextEditingController は画面が消えるときに片付ける必要があります。
  final emailController = TextEditingController();//	メールアドレス
  final passwordController = TextEditingController();//パスワード

  bool isLoading = false;//新規登録中かどうかを表します。
  String? errorText;

  @override
  //dispose は、使い終わった道具を片付ける処理
  void dispose() {
    displayNameController.dispose();
    departmentController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
  Future<void> register() async {
  setState(() {
    isLoading = true;
    errorText = null;
  });

  final displayName = displayNameController.text.trim();
  final department = departmentController.text.trim();
  final email = emailController.text.trim();
  final password = passwordController.text;

  if (displayName.isEmpty ||
      department.isEmpty ||
      email.isEmpty ||
      password.isEmpty) {
    setState(() {
      isLoading = false;
      errorText = 'すべての項目を入力してください。';
    });
    return;
  }

  try {
    final credential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      setState(() {
        errorText = 'ユーザー作成に失敗しました。';
      });
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'displayName': displayName,
      'email': email,
      'department': department,
      'photoUrl': '',
      'defaultRole': 'member',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      Navigator.of(context).pop();
    }
  } on FirebaseAuthException catch (e) {
    setState(() {
      errorText = e.message ?? '新規登録に失敗しました。';
    });
  } on FirebaseException catch (e) {
    setState(() {
      errorText = e.message ?? 'プロフィール保存に失敗しました。';
    });
  } catch (_) {
    setState(() {
      errorText = '新規登録に失敗しました。';
    });
  } finally {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}



  @override
  Widget build(BuildContext context) {
    //Scaffold は、画面の基本の土台
    return Scaffold(
      backgroundColor: AppColors.bg,
      //AppBar は、画面上部のバー
      appBar: AppBar(
        title: const Text('新規登録'),
      ),
//SafeArea は、スマホのノッチやステータスバーに画面が重ならないようにする部品
      body: SafeArea(
        child: SingleChildScrollView( //画面が小さいときにスクロールできるようにする部品
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox( //横幅の最大サイズを決める部品
              constraints: const BoxConstraints(maxWidth: 420),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'プロフィール作成',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'チームで使う名前とログイン情報を入力します',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.subText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppTextField(
                      controller: displayNameController,
                      label: '名前',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: departmentController,
                      label: '所属',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: emailController,
                      label: 'メールアドレス',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: passwordController,
                      label: 'パスワード',
                      obscureText: true,
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      ErrorBox(message: errorText!),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: isLoading ? null : register,
                      child: Text(isLoading ? '登録中...' : '新規登録'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  String? errorText;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorText = e.message ?? 'ログインに失敗しました。';
      });
    } catch (_) {
      setState(() {
        errorText = 'ログインに失敗しました。';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'WClinic Task Board',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.lineGreen,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'チームの会話のように、タスクを共有する',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.subText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 28),
                    AppTextField(
                      controller: emailController,
                      label: 'メールアドレス',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: passwordController,
                      label: 'パスワード',
                      obscureText: true,
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      ErrorBox(message: errorText!),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: isLoading ? null : login,
                      child: Text(isLoading ? 'ログイン中...' : 'ログイン'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                            //push は、新しい画面を上に重ねて表示する命令
                              Navigator.of(context).push( //Navigator は、画面を移動するための仕組み
                                MaterialPageRoute( //Material Design風に画面移動するための部品
                                  builder: (_) => const RegisterPage(),
                                ),
                              );
                            },
                      child: const Text('新規登録はこちら'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}





/*
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('ログイン画面'),
      ),
    );
  }
}
*/


class LoadingPage extends StatelessWidget {
  const LoadingPage({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
}

//ログアウト
//Future<void> は、時間がかかる処理を表します。
//async は、時間がかかる処理を待てるようにする書き方です。
//await は、処理が終わるまで待つ命令です。
class TeamListPage extends StatefulWidget {
  const TeamListPage({super.key});

  @override
  State<TeamListPage> createState() => _TeamListPageState();
}

//TaskListPageを作る
//これで、チーム内のタスク一覧画面ができます。
class TaskListPage extends StatefulWidget {
  const TaskListPage({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  final String teamId;
  final String teamName;

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}


//メンバー追加では、メールアドレス入力欄を使います。
//そのため、MemberListPage を StatefulWidget にします。
class MemberListPage extends StatefulWidget {
  const MemberListPage({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  final String teamId;
  final String teamName;

  @override
  State<MemberListPage> createState() => _MemberListPageState();
}

class _MemberListPageState extends State<MemberListPage> {
  final emailController = TextEditingController();

//選択中の権限を保存する変数を作る
//selectedMemberRole は、現在選ばれている権限を覚えるための変数です。
String selectedMemberRole = 'member';
//権限変更用の変数を作る
//selectedEditRole は、権限変更画面で選ばれている権限を覚える変数
String selectedEditRole = 'member';

  bool isAdding = false;
  String? errorText;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('${widget.teamName}のメンバー'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('teams')
            .doc(widget.teamId)
            .collection('members')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingPage(message: 'メンバーを読み込んでいます...');
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ErrorBox(
                  message: 'メンバー一覧の取得に失敗しました。',
                ),
              ),
            );
          }

          final members = snapshot.data?.docs ?? [];

          if (members.isEmpty) {
            return const Center(
              child: Text(
                'まだメンバーがいません。',
                style: TextStyle(
                  color: AppColors.subText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = members[index];
              final data = doc.data();

              final displayName =
                  (data['displayName'] ?? '名前未設定').toString();
              final email = (data['email'] ?? '').toString();
              final roleText = (data['role'] ?? 'member').toString();
              final role = teamRoleFromString(roleText);

              return MemberCard(
  displayName: displayName,
  email: email,
  role: role,
  onTap: () async {
    final myRole = await getMyRole();

    if (!canChangeMemberRole(myRole)) {
      showNoPermissionMessage();
      return;
    }

    if (role == TeamRole.owner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('オーナーの権限はこの画面では変更できません。'),
        ),
      );
      return;
    }

    showEditMemberRoleSheet(
      targetUid: doc.id,
      displayName: displayName,
      email: email,
      currentRole: role,
    );
  },
);

            },
          );
        },
      ),

      //右下の＋ボタンにつなげる
      floatingActionButton: FloatingActionButton(
        onPressed: showAddMemberSheet,
        child: const Icon(Icons.add),
      ),
    );
  }


//メンバー追加ボトムシートを作る
//これで、右下の + からメール入力画面を出せます。
Future<void> showAddMemberSheet() async {
  emailController.clear();
  //ボトムシートを開くときに初期化する
  selectedMemberRole = 'member';
  errorText = null;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'メンバーを追加',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: emailController,
                    label: 'メールアドレス',
                    keyboardType: TextInputType.emailAddress,
                  ),

                  //権限チップUIを追加する
                    const SizedBox(height: 16),
                  const Text(
                    '権限',
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('管理者'),
                        selected: selectedMemberRole == 'admin',
                        onSelected: (_) {
                          setSheetState(() {
                            selectedMemberRole = 'admin';
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('メンバー'),
                        selected: selectedMemberRole == 'member',
                        onSelected: (_) {
                          setSheetState(() {
                            selectedMemberRole = 'member';
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('閲覧者'),
                        selected: selectedMemberRole == 'viewer',
                        onSelected: (_) {
                          setSheetState(() {
                            selectedMemberRole = 'viewer';
                          });
                        },
                      ),
                    ],
                  ),

                  //権限チップの下に説明文を追加する
                  const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        roleDescription(selectedMemberRole),
                        style: const TextStyle(
                          color: AppColors.subText,
                          height: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),



                                    if (errorText != null) ...[
                                      const SizedBox(height: 12),
                                      ErrorBox(message: errorText!),
                                      ],

                                    const SizedBox(height: 16),
                                    FilledButton(
                                      onPressed: isAdding
                                          ? null
                                          : () async {
                                              await addMemberByEmail(setSheetState);
                                            },
                                      child: Text(isAdding ? '追加中...' : '追加する'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }



//メンバー追加処理を作る
//これで、メールアドレスから登録済みユーザーを検索して、チームに追加できます。

//追加処理があるか確認する
Future<void> addMemberByEmail(StateSetter setSheetState) async {
  final email = emailController.text.trim();

  if (email.isEmpty) {
    setSheetState(() {
      errorText = 'メールアドレスを入力してください。';
    });
    return;
  }

  setSheetState(() {
    isAdding = true;
    errorText = null;
  });

  try {
    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      setSheetState(() {
        errorText = 'このメールアドレスのユーザーは見つかりません。';
      });
      return;
    }

    final userDoc = userQuery.docs.first;
    final userData = userDoc.data();

    final uid = userDoc.id;
    final displayName =
        (userData['displayName'] ?? '名前未設定').toString();
    final userEmail = (userData['email'] ?? email).toString();

    final memberRef = FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .collection('members')
        .doc(uid);

    final memberDoc = await memberRef.get();

    if (memberDoc.exists) {
      setSheetState(() {
        errorText = 'このユーザーはすでにメンバーです。';
      });
      return;
    }

    await memberRef.set({
      'uid': uid,
      'email': userEmail,
      'displayName': displayName,
      'role': selectedMemberRole,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .update({
      'memberIds': FieldValue.arrayUnion([uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      Navigator.of(context).pop();
    }
  } on FirebaseException catch (e) {
    setSheetState(() {
      errorText = e.message ?? 'メンバー追加に失敗しました。';
    });
  } catch (_) {
    setSheetState(() {
      errorText = 'メンバー追加に失敗しました。';
    });
  } finally {
    if (mounted) {
      setSheetState(() {
        isAdding = false;
      });
    }
  }
}


//roleDescriptionを作る
String roleDescription(String role) {
  switch (role) {
    case 'admin':
      return '院内タスクの管理、メンバー管理、タスク削除ができます。';
    case 'viewer':
      return '院内タスクの確認のみできます。編集はできません。';
    case 'member':
    default:
      return '院内タスクの作成・編集ができます。';
  }
}



//自分の権限を取得する関数を作る
Future<TeamRole> getMyRole() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return TeamRole.viewer;
  }

  final memberDoc = await FirebaseFirestore.instance
      .collection('teams')
      .doc(widget.teamId)
      .collection('members')
      .doc(user.uid)
      .get();

  final data = memberDoc.data();
  final roleText = data?['role']?.toString();

  return teamRoleFromString(roleText);
  }

  //ownerかどうかを判定する関数を作る
  //意味　ownerならtrue  owner以外ならfalse

  bool canChangeMemberRole(TeamRole role) {
  return role == TeamRole.owner;
  }

  //権限がないときのメッセージを作る
  //SnackBar は、画面下に出る短いメッセージ
  void showNoPermissionMessage() {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('権限を変更できるのはオーナーのみです。'),
      ),
    );
  }


  //権限変更ボトムシートを作る
  //これで、権限変更用のボトムシートができます。
    Future<void> showEditMemberRoleSheet({
  required String targetUid,
  required String displayName,
  required String email,
  required TeamRole currentRole,
}) async {
  selectedEditRole = currentRole.name;
  errorText = null;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const Text(
                    '権限を変更',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              color: AppColors.subText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '新しい権限',
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('管理者'),
                        selected: selectedEditRole == 'admin',
                        onSelected: (_) {
                          setSheetState(() {
                            selectedEditRole = 'admin';
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('メンバー'),
                        selected: selectedEditRole == 'member',
                        onSelected: (_) {
                          setSheetState(() {
                            selectedEditRole = 'member';
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('閲覧者'),
                        selected: selectedEditRole == 'viewer',
                        onSelected: (_) {
                          setSheetState(() {
                            selectedEditRole = 'viewer';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      roleDescription(selectedEditRole),
                      style: const TextStyle(
                        color: AppColors.subText,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    ErrorBox(message: errorText!),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      await updateMemberRole(
                        setSheetState: setSheetState,
                        targetUid: targetUid,
                        );
                      },
                      child: const Text('変更する'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  //Firestoreを更新する処理を作る
  Future<void> updateMemberRole({
  required StateSetter setSheetState,
  required String targetUid,
    }) async {
      try {
        await FirebaseFirestore.instance
            .collection('teams')
            .doc(widget.teamId)
            .collection('members')
            .doc(targetUid)
            .update({
          'role': selectedEditRole,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.of(context).pop();
        }
      } on FirebaseException catch (e) {
        setSheetState(() {
          errorText = e.message ?? '権限変更に失敗しました。';
        });
      } catch (_) {
        setSheetState(() {
          errorText = '権限変更に失敗しました。';
        });
      }
    }

}


//MemberCardを作る
//MemberCard は、メンバー1人分の表示部品
class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.displayName,
    required this.email,
    required this.role,
    required this.onTap,
  });

  final String displayName;
  final String email;
  final TeamRole role;
  final VoidCallback onTap;


 @override
Widget build(BuildContext context) {
  return AppCard(
    onTap: onTap,
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.lineGreen,
          child: Text(
            displayName.isNotEmpty ? displayName.substring(0, 1) : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        _Label(text: teamRoleLabel(role)),
      ],
    ),
  );
}
  
}


class _TaskListPageState extends State<TaskListPage> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final assigneeEmailController = TextEditingController();

  String selectedPriority = 'normal';
  String selectedStatus = 'todo';

  bool isCreating = false;
  String? errorText;

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    assigneeEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.chatBg,

      //TaskListPageにメンバー画面へのボタンを追加する
      appBar: AppBar(
        title: Text(widget.teamName),
        actions: [
          IconButton(
            tooltip: 'メンバー',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MemberListPage(
                    teamId: widget.teamId,
                    teamName: widget.teamName,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.group),
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('teams')
            .doc(widget.teamId)
            .collection('tasks')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingPage(message: 'タスクを読み込んでいます...');
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ErrorBox(
                  message: 'タスク一覧の取得に失敗しました。',
                ),
              ),
            );
          }

          final tasks = snapshot.data?.docs ?? [];

          if (tasks.isEmpty) {
            return const Center(
              child: Text(
                'まだタスクがありません。\n右下の＋から作成できます。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.subText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = tasks[index];
              final data = doc.data();

              final title = (data['title'] ?? '無題のタスク').toString();
              final description = (data['description'] ?? '').toString();
              final status = (data['status'] ?? 'todo').toString();
              final priority = (data['priority'] ?? 'normal').toString();
              final assigneeEmail = (data['assigneeEmail'] ?? '').toString();

              return Dismissible(
                key: ValueKey(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),

                //タスク削除で使う
                confirmDismiss: (_) async {

                  //role が TeamRole になったので、文字列ではなくDartの権限として判定できます。
                  final role = await getMyRole();

                  if (!canDeleteTaskByRole(role)) {
                    showNoPermissionMessage();
                    return false;
                  }

                  return confirmDeleteTask(title);
                },
                onDismissed: (_) async {
                  await deleteTask(doc.id);
                },
                child: TaskCard(
                  title: title,
                  description: description,
                  status: status,
                  priority: priority,
                  assigneeEmail: assigneeEmail,

                  //これで、viewer は編集できなくなります。
                  onTap: () async {
                    final role = await getMyRole();

                    if (!canEditTask(role)) {
                      showNoPermissionMessage();
                      return;
                    }

                    showEditTaskSheet(
                      taskId: doc.id,
                      currentTitle: title,
                      currentDescription: description,
                      currentAssigneeEmail: assigneeEmail,
                      currentPriority: priority,
                      currentStatus: status,
                    );
                  },

                ),
              );

            },
          );
        },
      ),

      //タスク作成ボタンで使う
        floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final role = await getMyRole();

          if (!canCreateTask(role)) {
            showNoPermissionMessage();
            return;
          }

          showCreateTaskSheet();
        },
        child: const Icon(Icons.add),
      ),

    );
  }

  //タスク作成ボトムシートを作成
  Future<void> showCreateTaskSheet() async {
  titleController.clear();
  descriptionController.clear();
  assigneeEmailController.clear();

  selectedPriority = 'normal';
  selectedStatus = 'todo';

  errorText = null;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '新しいタスクを作成',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  /*
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: titleController,
                    label: 'タスク名',
                  ),
                  */

                //医療機関向け
                  AppTextField(
                  controller: titleController,
                  label: '院内タスク名',
                ),

                  const SizedBox(height: 12),

                  /*
                  AppTextField(
                    controller: descriptionController,
                    label: '説明',
                    maxLines: 3,
                  ),
                  */

                  //医療機関向け
                  AppTextField(
                  controller: descriptionController,
                  label: '対応内容',
                  maxLines: 3,
                ),
                /*
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: assigneeEmailController,
                    label: '担当者メール',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  */

                  AppTextField(
                  controller: assigneeEmailController,
                  label: '担当者のメールアドレス',
                  keyboardType: TextInputType.emailAddress,
                ),

                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: const InputDecoration(
                      labelText: '優先度',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'low',
                        child: Text('低'),
                      ),
                      DropdownMenuItem(
                        value: 'normal',
                        child: Text('中'),
                      ),
                      DropdownMenuItem(
                        value: 'high',
                        child: Text('高'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setSheetState(() {
                        selectedPriority = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'ステータス',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'todo',
                        child: Text('未対応'),
                      ),
                      DropdownMenuItem(
                        value: 'doing',
                        child: Text('進行中'),
                      ),
                      DropdownMenuItem(
                        value: 'done',
                        child: Text('完了'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setSheetState(() {
                        selectedStatus = value;
                      });
                    },
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    ErrorBox(message: errorText!),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: isCreating
                        ? null
                        : () async {
                            await createTask(setSheetState);
                          },
                    child: Text(isCreating ? '作成中...' : '作成する'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

//保存処理
Future<void> createTask(StateSetter setSheetState) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    setSheetState(() {
      errorText = 'ログイン状態を確認できません。';
    });
    return;
  }

  final title = titleController.text.trim();
  final description = descriptionController.text.trim();
  final assigneeEmail = assigneeEmailController.text.trim();

  if (title.isEmpty) {
    setSheetState(() {
      errorText = 'タスク名を入力してください。';
    });
    return;
  }

  setSheetState(() {
    isCreating = true;
    errorText = null;
  });

  try {
    await FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .collection('tasks')
        .add({
      'title': title,//タスク名
      'description': description,//説明
      'assigneeEmail': assigneeEmail,//担当者メール
      'assigneeId': '',//担当者uid。今回は空
      'priority': selectedPriority,//優先度
      'status': selectedStatus,//ステータス
      'createdBy': user.uid,//作成者uid
      'createdAt': FieldValue.serverTimestamp(),//作成日時
      'updatedAt': FieldValue.serverTimestamp(),//更新日時
    });

    if (mounted) {
      Navigator.of(context).pop();
    }
  } on FirebaseException catch (e) {
    setSheetState(() {
      errorText = e.message ?? 'タスク作成に失敗しました。';
    });
  } catch (_) {
    setSheetState(() {
      errorText = 'タスク作成に失敗しました。';
    });
  } finally {
    if (mounted) {
      setSheetState(() {
        isCreating = false;
      });
    }
  }
}

//編集用ボトムシートを作る
Future<void> showEditTaskSheet({
  required String taskId,
  required String currentTitle,
  required String currentDescription,
  required String currentAssigneeEmail,
  required String currentPriority,
  required String currentStatus,
}) async {
  titleController.text = currentTitle;
  descriptionController.text = currentDescription;
  assigneeEmailController.text = currentAssigneeEmail;

  selectedPriority = currentPriority;
  selectedStatus = currentStatus;

  errorText = null;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'タスクを編集',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: titleController,
                    label: 'タスク名',
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: descriptionController,
                    label: '説明',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: assigneeEmailController,
                    label: '担当者メール',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: const InputDecoration(
                      labelText: '優先度',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'low',
                        child: Text('低'),
                      ),
                      DropdownMenuItem(
                        value: 'normal',
                        child: Text('中'),
                      ),
                      DropdownMenuItem(
                        value: 'high',
                        child: Text('高'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setSheetState(() {
                        selectedPriority = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'ステータス',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'todo',
                        child: Text('未対応'),
                      ),
                      DropdownMenuItem(
                        value: 'doing',
                        child: Text('進行中'),
                      ),
                      DropdownMenuItem(
                        value: 'done',
                        child: Text('完了'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setSheetState(() {
                        selectedStatus = value;
                      });
                    },
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    ErrorBox(message: errorText!),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: isCreating
                        ? null
                        : () async {
                            await updateTask(
                              setSheetState: setSheetState,
                              taskId: taskId,
                            );
                          },
                    child: Text(isCreating ? '更新中...' : '更新する'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

//更新処理 updateTask() を作る
Future<void> updateTask({
  required StateSetter setSheetState,
  required String taskId,
}) async {
  final title = titleController.text.trim();
  final description = descriptionController.text.trim();
  final assigneeEmail = assigneeEmailController.text.trim();

  if (title.isEmpty) {
    setSheetState(() {
      errorText = 'タスク名を入力してください。';
    });
    return;
  }

  setSheetState(() {
    isCreating = true;
    errorText = null;
  });

  try {
    await FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .collection('tasks')
        .doc(taskId)
        .update({
      'title': title,
      'description': description,
      'assigneeEmail': assigneeEmail,
      'priority': selectedPriority,
      'status': selectedStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      Navigator.of(context).pop();
    }
  } on FirebaseException catch (e) {
    setSheetState(() {
      errorText = e.message ?? 'タスク更新に失敗しました。';
    });
  } catch (_) {
    setSheetState(() {
      errorText = 'タスク更新に失敗しました。';
    });
  } finally {
    if (mounted) {
      setSheetState(() {
        isCreating = false;
      });
    }
  }
}

//getMyRoleをTeamRole対応にする
Future<TeamRole> getMyRole() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return TeamRole.viewer;
  }

  final memberDoc = await FirebaseFirestore.instance
      .collection('teams')
      .doc(widget.teamId)
      .collection('members')
      .doc(user.uid)
      .get();

  final data = memberDoc.data();
  final roleText = data?['role']?.toString();

  return teamRoleFromString(roleText);
}


//admin以上か確認する関数を作る
bool canDeleteTask(String? role) {
  return role == 'owner' || role == 'admin';
}

//タスク削除処理を作る
Future<void> deleteTask(String taskId) async {
  await FirebaseFirestore.instance
      .collection('teams')
      .doc(widget.teamId)
      .collection('tasks')
      .doc(taskId)
      .delete();
}


//削除確認ダイアログを作る
Future<bool> confirmDeleteTask(String taskTitle) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('タスクを削除しますか？'),
        content: Text('「$taskTitle」を削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('削除する'),
          ),
        ],
      );
    },
  );

  return result == true;
}

//権限がないときのメッセージを作る
void showNoPermissionMessage() {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('この操作を行う権限がありません。'),
    ),
  );
}
}

class _TeamListPageState extends State<TeamListPage> {
  final teamNameController = TextEditingController();

  bool isCreating = false;
  String? errorText;

  @override
  void dispose() {
    teamNameController.dispose();
    super.dispose(); //dispose() は、使い終わったControllerを片付ける処理
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> showCreateTeamSheet() async {
  teamNameController.clear();
  errorText = null;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder( //shape は、ボトムシートの形を決める設定
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (context) {

      //StatefulBuilder は、ボトムシートの中だけを更新するために使います。
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,

              //これは、スマホでキーボードが出たときに、入力欄が隠れないようにするための設定
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '新しいチームを作成',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: teamNameController,
                  label: 'チーム名',
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 12),
                  ErrorBox(message: errorText!),
                ],
                const SizedBox(height: 16),

                //作成中ではない→ボタンを押せる→createTeam() が動く
                //作成中→ボタンを押せない→文字が「作成中...」になる
                FilledButton(
                  onPressed: isCreating
                      ? null
                      : () async {

                        //createTeam(setSheetState) は、チームをFirestoreに保存する処理
                          await createTeam(setSheetState);
                        },
                  child: Text(isCreating ? '作成中...' : '作成する'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}


  Future<void> createTeam(StateSetter setSheetState) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setSheetState(() {
        errorText = 'ログイン状態を確認できません。';
      });
      return;
    }

    final teamName = teamNameController.text.trim();

    if (teamName.isEmpty) {
      setSheetState(() {
        errorText = 'チーム名を入力してください。';
      });
      return;
    }

    setSheetState(() {
      isCreating = true;
      errorText = null;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data();

      final displayName =
          (userData?['displayName'] ?? user.email ?? '名無し').toString();

      final email = (userData?['email'] ?? user.email ?? '').toString();

      final teamRef = await FirebaseFirestore.instance.collection('teams').add({
        'name': teamName,
        'ownerId': user.uid,
        'memberIds': [user.uid],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await teamRef.collection('members').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'displayName': displayName,
        'role': 'owner',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseException catch (e) {
      setSheetState(() {
        errorText = e.message ?? 'チーム作成に失敗しました。';
      });
    } catch (_) {
      setSheetState(() {
        errorText = 'チーム作成に失敗しました。';
      });
    } finally {
      if (mounted) {
        setSheetState(() {
          isCreating = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('ログイン状態を確認できません。'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('トーク'),
        actions: [
          IconButton(
            tooltip: 'ログアウト',
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('teams')
            .where('memberIds', arrayContains: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingPage(message: 'チームを読み込んでいます...');
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ErrorBox(
                  message: 'チーム一覧の取得に失敗しました。',
                ),
              ),
            );
          }

          final teams = snapshot.data?.docs ?? [];

          if (teams.isEmpty) {
            return const Center(
              child: Text(
                'まだチームがありません。\n右下の＋から作成できます。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.subText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }
        //TeamCardをDismissibleで包む
          return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: teams.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
    final doc = teams[index];
    final data = doc.data();

    final name = (data['name'] ?? '無題のチーム').toString();

    return Dismissible( //Dismissible は、スワイプで消せる一覧項目を作るWidget
    key: ValueKey(doc.id), //key は、一覧の中の1件を区別するための印
    direction: DismissDirection.endToStart,

    //赤い削除背景を作成
    background: Container(
    alignment: Alignment.centerRight, //alignment: Alignment.centerRight にすることで、右側に削除アイコンを表示します。
    padding: const EdgeInsets.only(right: 20),
    decoration: BoxDecoration(
      color: AppColors.danger,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Icon(
      Icons.delete,
      color: Colors.white,
    ),
  ),

  //削除前に確認する
  //confirmDismiss は、スワイプ後に本当に削除してよいか確認する場所
  //ここで true が返ると、削除が進みます。 false が返ると、元に戻ります。
  confirmDismiss: (_) async {
    return confirmDeleteTeam(name);
  },

  //onDismissed は、スワイプ削除が確定したあとに動きます。
  onDismissed: (_) async {
    await deleteTeam(doc.id);
  },
child: TeamCard(
    name: name,
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TaskListPage(
            teamId: doc.id,
            teamName: name,
          ),
        ),
      );
    },
  ),
);
          
        },
      );
        }
      ),
      //onPressed: showCreateTeamSheet にすることで、右下の + を押したときにボトムシートが開きます。
      floatingActionButton: FloatingActionButton(
        onPressed: showCreateTeamSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  //これは、Firestoreの teams/{teamId} を削除する処理です。
  //teamId は、削除したいチームのID
  Future<void> deleteTeam(String teamId) async {
  await FirebaseFirestore.instance.collection('teams').doc(teamId).delete();
}

//削除確認ダイアログ作成
Future<bool> confirmDeleteTeam(String teamName) async {
  final result = await showDialog<bool>( //showDialog は、確認用の小さな画面を出す命令  true が返ったら削除します。false なら削除しません。
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('チームを削除しますか？'),
        content: Text('「$teamName」を削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('削除する'),
          ),
        ],
      );
    },
  );

  return result == true;
  
}
}



// 3. テーマで使用しているカラー定義（コメントアウトから復活）
/*
class AppColors {
  static const bg = Color(0xFFF3F4F6);
  static const chatBg = Color(0xFFECEFF1);
  static const card = Colors.white;
  static const lineGreen = Color(0xFF06C755);
  static const lineGreenDark = Color(0xFF00B900);
  static const text = Color(0xFF111111);
  static const subText = Color(0xFF8A8A8A);
  static const border = Color(0xFFE5E5E5);
  static const danger = Color(0xFFE53935);
  static const success = Color(0xFF06C755);
  static const warning = Color(0xFFFFB300);

  static const primary = lineGreen;
}
*/
class AppColors {
  static const bg = Color(0xFFF5F8FB);
  static const chatBg = Color(0xFFEAF2F8);
  static const card = Colors.white;

  static const lineGreen = Color(0xFF2F80ED);
  static const lineGreenDark = Color(0xFF1C5FB8);

  static const text = Color(0xFF111827);
  static const subText = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);

  static const danger = Color(0xFFE53935);
  static const success = Color(0xFF2F80ED);
  static const warning = Color(0xFFFFB300);

  static const primary = lineGreen;
}

