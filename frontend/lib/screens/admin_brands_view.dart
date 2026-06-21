import '../utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/category.dart';

class AdminBrandsView extends StatefulWidget {
  const AdminBrandsView({super.key});
  @override State<AdminBrandsView> createState() => _AdminBrandsViewState();
}

class _AdminBrandsViewState extends State<AdminBrandsView> {
  final _name = TextEditingController();
  final _slug = TextEditingController();
  final _logo = TextEditingController();
  bool _active = true, _loading = true, _saving = false;
  Brand? _editing;
  List<Brand> _brands = [];

  @override void initState(){ super.initState(); _fetch(); }
  Future<void> _fetch() async { setState(()=>_loading=true); final r=await http.get(Uri.parse('${AppConstants.apiUrl}/brands')); if(mounted){ setState((){ _brands = r.statusCode==200 ? (json.decode(r.body) as List).map((e)=>Brand.fromJson(e)).toList() : []; _loading=false; }); }}
  void _edit(Brand? b){ setState((){ _editing=b; _name.text=b?.name??''; _slug.text=b?.slug??''; _logo.text=b?.logoUrl??''; _active=b?.isActive??true; }); }
  Future<void> _save() async { if(_name.text.trim().isEmpty) return; setState(()=>_saving=true); final token=context.read<AuthProvider>().token; final body=json.encode({'name':_name.text.trim(),'slug':_slug.text.trim().isEmpty?null:_slug.text.trim(),'logo_url':_logo.text.trim(),'is_active':_active}); final uri=Uri.parse('${AppConstants.apiUrl}/brands${_editing==null?'':'/${_editing!.id}'}'); final r=_editing==null?await http.post(uri,headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:body):await http.put(uri,headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:body); if(mounted){ setState(()=>_saving=false); if(r.statusCode==200||r.statusCode==201){ _edit(null); _fetch(); } }}
  Future<void> _delete(Brand b) async { final token=context.read<AuthProvider>().token; await http.delete(Uri.parse('${AppConstants.apiUrl}/brands/${b.id}'),headers:{'Authorization':'Bearer $token'}); _fetch(); }
  @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Manage Brands',style:Theme.of(context).textTheme.headlineMedium),const SizedBox(height:16),Card(child:Padding(padding:const EdgeInsets.all(16),child:Wrap(spacing:12,runSpacing:12,crossAxisAlignment:WrapCrossAlignment.center,children:[SizedBox(width:220,child:TextField(controller:_name,decoration:const InputDecoration(labelText:'Brand name'))),SizedBox(width:220,child:TextField(controller:_slug,decoration:const InputDecoration(labelText:'Slug (optional)'))),SizedBox(width:260,child:TextField(controller:_logo,decoration:const InputDecoration(labelText:'Logo URL'))),FilterChip(label:const Text('Active'),selected:_active,onSelected:(v)=>setState(()=>_active=v)),ElevatedButton(onPressed:_saving?null:_save,child:Text(_editing==null?'Add Brand':'Update Brand')),TextButton(onPressed:()=>_edit(null),child:const Text('Clear'))]))),const SizedBox(height:16),Expanded(child:_loading?const Center(child:CircularProgressIndicator()):ListView.separated(itemCount:_brands.length,separatorBuilder:(_,__)=>const Divider(),itemBuilder:(c,i){final b=_brands[i];return ListTile(leading:b.logoUrl.isEmpty?const Icon(Icons.sell_outlined):Image.network(b.logoUrl,width:44,height:44,errorBuilder:(_,__,___)=>const Icon(Icons.sell_outlined)),title:Text(b.name),subtitle:Text('${b.slug} • ${b.isActive?'Active':'Inactive'}'),trailing:Wrap(children:[IconButton(icon:const Icon(Icons.edit),onPressed:()=>_edit(b)),IconButton(icon:const Icon(Icons.delete,color:Colors.red),onPressed:()=>_delete(b))]));}))]);
}
