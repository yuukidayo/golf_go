import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/plan.dart';
import '../../theme/app_theme.dart';

class PlanCreateScreen extends StatefulWidget {
  final Plan? plan; // 編集する既存のプラン（新規作成の場合はnull）
  
  const PlanCreateScreen({super.key, this.plan});

  @override
  State<PlanCreateScreen> createState() => _PlanCreateScreenState();
}

class _PlanCreateScreenState extends State<PlanCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isPublic = true;
  bool _isSubmitting = false;
  bool _isEditMode = false;
  String? _planId; // 編集中のプランID
  

  
  // エラーメッセージを表示
  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  @override
  void initState() {
    super.initState();
    
    // 既存プランのデータがある場合は編集モードとして初期化
    if (widget.plan != null) {
      _isEditMode = true;
      _planId = widget.plan!.id;
      
      // テキストフィールドの初期化
      _titleController.text = widget.plan!.title;
      _descriptionController.text = widget.plan!.description;
      
      // 公開状態の設定
      _isPublic = widget.plan!.isPublic;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }



  // プランを保存
  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Firebaseにプラン情報を保存
    try {
      setState(() {
        _isSubmitting = true;
      });

      // 現在のユーザーIDを取得
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showError('認証エラーが発生しました。再度ログインしてください');
        return;
      }

      // Firestore参照
      final plansCollection = FirebaseFirestore.instance.collection('plans');

      // 新規作成または更新
      if (_isEditMode && _planId != null) {
        // 更新の場合
        await plansCollection.doc(_planId).update({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'isPublic': _isPublic,
          'isActive': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // 新規作成の場合
        await plansCollection.add({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'coachId': currentUser.uid,
          'isPublic': _isPublic,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.pop(context, true); // 保存成功を伝えてポップ
      }
    } catch (e) {
      _showError('保存中にエラーが発生しました: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'プランの編集' : 'プランの登録',
          style: TextStyle(
            color: AppColors.luxuryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFDFBC57),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // レッスン詳細セクション
                const Text(
                  'レッスン詳細',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                // レッスンタイトル
                Row(
                  children: [
                    const Text(
                      'レッスンタイトル',
                      style: TextStyle(fontSize: 16),
                    ),
                    const Text(
                      '*',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '飛距離アップ集中レッスン',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'タイトルを入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // レッスン内容
                const Text(
                  'レッスン内容',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'レッスンの内容や特徴を入力してください',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 24),
                
                // 公開設定
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF9E7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.public, color: Colors.amber),
                      const SizedBox(width: 8),
                      const Text('登録すると一般ユーザーに公開されます'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // 登録/更新ボタン
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _savePlan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isEditMode ? '更新' : '登録',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // キャンセルボタン
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'キャンセル',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
