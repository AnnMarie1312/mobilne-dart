import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const TravelWithUsApp());
}

class TravelWithUsApp extends StatelessWidget {
  const TravelWithUsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TravelWithUs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF247BA0),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// API adresa za Chrome i Android emulator.



class ApiService {
  static const String baseUrl =
        'https://travelwithus.hosted.hostna.com/api';

  // PRIJAVA KORISNIKA
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login.php'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['status'] != 'success') {
      throw Exception(data['message'] ?? 'Prijava nije uspjela.');
    }

    if ((data['token'] ?? '').toString().isEmpty) {
      throw Exception('API nije vratio token za prijavu.');
    }

    return data;
  }

  // REGISTRACIJA KORISNIKA
  static Future<Map<String, dynamic>> register({
    required String ime,
    required String prezime,
    required String telefon,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register.php'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'ime': ime,
        'prezime': prezime,
        'telefon': telefon,
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 201 || data['status'] != 'success') {
      throw Exception(
        data['message'] ?? 'Registracija nije uspjela.',
      );
    }

    return data;
  }

  
  // DOHVAT PUTOVANJA
  static Future<List<dynamic>> getPutovanja(String token) async {
    print('TOKEN POSTOJI: ${token.trim().isNotEmpty}');

    final response = await http.get(
      Uri.parse('$baseUrl/putovanje.php'),
      headers: {
        'Authorization': 'Bearer $token',
        'X-Auth-Token': token,
        'Accept': 'application/json',
      },
    );

  

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['status'] != 'success') {
      throw Exception(
        data['message'] ?? 'Dohvat putovanja nije uspio.',
      );
    }

    return data['putovanja'] as List<dynamic>? ?? [];
  }




  // DOHVAT AKTIVNOSTI I KATEGORIJA ZA ODABRANO PUTOVANJE
  static Future<Map<String, dynamic>> getAktivnostiPodaci(
    String token,
    int idPutovanja,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/aktivnosti.php?id_putovanja=$idPutovanja',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'X-Auth-Token': token,
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['status'] != 'success') {
      throw Exception(
        data['message'] ?? 'Dohvat aktivnosti nije uspio.',
      );
    }

    return {
      'aktivnosti': data['aktivnosti'] as List<dynamic>? ?? [],
      'kategorije': data['kategorije'] as List<dynamic>? ?? [],
    };
  }

  // ZAJEDNICKA METODA ZA SLANJE PODATAKA AKTIVNOSTI
  static Future<void> _posaljiAktivnost({
    required String endpoint,
    required String token,
    required Map<String, dynamic> podaci,
    required int uspjesanStatus,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'X-Auth-Token': token,
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(podaci),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != uspjesanStatus ||
        data['status'] != 'success') {
      throw Exception(
        data['message'] ?? 'Spremanje aktivnosti nije uspjelo.',
      );
    }
  }

  // DODAVANJE NOVE AKTIVNOSTI
  static Future<void> dodajAktivnost({
    required String token,
    required int idPutovanja,
    required String naziv,
    required String opis,
    required int idKategorija,
    required int trajanje,
    required int dan,
    required String vrijeme,
    required double cijena,
  }) async {
    await _posaljiAktivnost(
      endpoint: 'dodaj_aktivnost.php',
      token: token,
      uspjesanStatus: 201,
      podaci: {
        'id_putovanja': idPutovanja,
        'naziv': naziv,
        'opis': opis,
        'id_kategorija': idKategorija,
        'trajanje': trajanje,
        'dan': dan,
        'vrijeme': vrijeme,
        'cijena': cijena,
      },
    );
  }

  // UREDIVANJE POSTOJECE AKTIVNOSTI
  static Future<void> urediAktivnost({
    required String token,
    required int idAktivnosti,
    required int idPutovanja,
    required String naziv,
    required String opis,
    required int idKategorija,
    required int trajanje,
    required int dan,
    required String vrijeme,
    required double cijena,
  }) async {
    await _posaljiAktivnost(
      endpoint: 'uredi_aktivnost.php',
      token: token,
      uspjesanStatus: 200,
      podaci: {
        'id_aktivnosti': idAktivnosti,
        'id_putovanja': idPutovanja,
        'naziv': naziv,
        'opis': opis,
        'id_kategorija': idKategorija,
        'trajanje': trajanje,
        'dan': dan,
        'vrijeme': vrijeme,
        'cijena': cijena,
      },
    );
  }

  // BRISANJE AKTIVNOSTI
  static Future<void> obrisiAktivnost({
    required String token,
    required int idAktivnosti,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/obrisi_aktivnost.php'),
      headers: {
        'Authorization': 'Bearer $token',
        'X-Auth-Token': token,
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'id_aktivnosti': idAktivnosti,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['status'] != 'success') {
      throw Exception(data['message'] ?? 'Brisanje aktivnosti nije uspjelo.');
    }
  }

  // DOHVAT TROŠKOVA I KATEGORIJA ZA ODABRANO PUTOVANJE
  static Future<Map<String, dynamic>> getTroskoviPodaci(
    String token,
    int idPutovanja,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/troskovi.php?id_putovanja=$idPutovanja'),
      headers: {
        'Authorization': 'Bearer $token',
        'X-Auth-Token': token,
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['status'] != 'success') {
      throw Exception(data['message'] ?? 'Dohvat troškova nije uspio.');
    }

    return {
      'troskovi': data['troskovi'] as List<dynamic>? ?? [],
      'kategorije': data['kategorije'] as List<dynamic>? ?? [],
      'ukupno': data['ukupno'] ?? 0,
    };
  }

  // ZAJEDNIČKA METODA ZA SLANJE PODATAKA TROŠKOVA
  static Future<void> _posaljiTrosak({
    required String endpoint,
    required String token,
    required Map<String, dynamic> podaci,
    required int uspjesanStatus,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'X-Auth-Token': token,
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(podaci),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != uspjesanStatus ||
        data['status'] != 'success') {
      throw Exception(data['message'] ?? 'Spremanje troška nije uspjelo.');
    }
  }

  // DODAVANJE NOVOG TROŠKA
  static Future<void> dodajTrosak({
    required String token,
    required int idPutovanja,
    required String trosak,
    required double iznos,
    required String opis,
    required int dan,
    required int idVrsteTroska,
  }) async {
    await _posaljiTrosak(
      endpoint: 'dodaj_trosak.php',
      token: token,
      uspjesanStatus: 201,
      podaci: {
        'id_putovanja': idPutovanja,
        'trosak': trosak,
        'iznos': iznos,
        'opis': opis,
        'dan': dan,
        'id_vrste_troska': idVrsteTroska,
      },
    );
  }

  // UREĐIVANJE POSTOJEĆEG TROŠKA
  static Future<void> urediTrosak({
    required String token,
    required int idTroskovi,
    required int idPutovanja,
    required String trosak,
    required double iznos,
    required String opis,
    required int dan,
    required int idVrsteTroska,
  }) async {
    await _posaljiTrosak(
      endpoint: 'uredi_trosak.php',
      token: token,
      uspjesanStatus: 200,
      podaci: {
        'id_troskovi': idTroskovi,
        'id_putovanja': idPutovanja,
        'trosak': trosak,
        'iznos': iznos,
        'opis': opis,
        'dan': dan,
        'id_vrste_troska': idVrsteTroska,
      },
    );
  }

  // BRISANJE TROŠKA
  static Future<void> obrisiTrosak({
    required String token,
    required int idTroskovi,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/obrisi_trosak.php'),
      headers: {
        'Authorization': 'Bearer $token',
        'X-Auth-Token': token,
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'id_troska': idTroskovi,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['status'] != 'success') {
      throw Exception(data['message'] ?? 'Brisanje troška nije uspjelo.');
    }
  }

  // BRISANJE PUTOVANJA
  static Future<void> obrisiPutovanje({
    required String token,
    required int idPutovanja,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/obrisi_putovanje.php'),
      headers: {
        'Authorization': 'Bearer $token',
        'X-Auth-Token': token,
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'id_putovanja': idPutovanja,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['status'] != 'success') {
      throw Exception(data['message'] ?? 'Brisanje putovanja nije uspjelo.');
    }
  }
}

// PRIJAVA
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unesi e-mail i lozinku.')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final data = await ApiService.login(email, password);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            token: data['token'].toString(),
            user: Map<String, dynamic>.from(data['user']),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/TravelWithUs.png',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'TravelWithUs',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF247BA0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Isplaniraj svoje sljedeće putovanje.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Dobro došli!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Prijavi se i nastavi planirati svoja putovanja.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: hidePassword,
                    onSubmitted: (_) => login(),
                    decoration: InputDecoration(
                      labelText: 'Lozinka',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            hidePassword = !hidePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF247BA0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Prijava',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),


                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () async {
                      final rezultat = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );

                      if (rezultat == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Registracija je uspješna. Sada se možeš prijaviti.',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Nemaš račun? Registriraj se'),
                  ),
            const SizedBox(height: 16),


                  const Text(
                    'TravelWithUs • Tvoj osobni planer putovanja',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _imeController = TextEditingController();
  final _prezimeController = TextEditingController();
  final _telefonController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _imeController.dispose();
    _prezimeController.dispose();
    _telefonController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ApiService.register(
        ime: _imeController.text.trim(),
        prezime: _prezimeController.text.trim(),
        telefon: _telefonController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: const Text('Registracija'),
        backgroundColor: const Color(0xFF247BA0),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.person_add_alt_1,
                      size: 64,
                      color: Color(0xFF247BA0),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Izradi račun',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF183B56),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Registriraj se i počni planirati putovanja.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 28),

                    TextFormField(
                      controller: _imeController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Ime',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Unesi ime.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _prezimeController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Prezime',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Unesi prezime.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _telefonController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefon',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Unesi broj telefona.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';

                        if (email.isEmpty || !email.contains('@')) {
                          return 'Unesi ispravnu e-mail adresu.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _hidePassword,
                      decoration: InputDecoration(
                        labelText: 'Lozinka',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _hidePassword = !_hidePassword;
                            });
                          },
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return 'Lozinka mora imati barem 8 znakova.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _hideConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Potvrdi lozinku',
                        prefixIcon: const Icon(Icons.lock_reset),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _hideConfirmPassword =
                                  !_hideConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _hideConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Lozinke se ne podudaraju.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF247BA0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Registriraj se',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
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

// DASHBOARD
class DashboardScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const DashboardScreen({
    super.key,
    required this.token,
    required this.user,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<dynamic>> putovanjaFuture;

  @override
  void initState() {
    super.initState();
    ucitajPutovanja();
  }

  void ucitajPutovanja() {
    putovanjaFuture = ApiService.getPutovanja(widget.token);
  }

  String formatDatum(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'Nije naveden';
    }

    final date = DateTime.tryParse(value.toString());

    if (date == null) return value.toString();

    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}.';
  }

  Future<void> osvjezi() async {
    setState(ucitajPutovanja);
    await putovanjaFuture;
  }

  // POTVRDA I BRISANJE ODABRANOG PUTOVANJA
  Future<void> potvrdiBrisanjePutovanja(Map<String, dynamic> putovanje) async {
    final idPutovanja = int.tryParse(
      putovanje['id_putovanja']?.toString() ?? '',
    );

    if (idPutovanja == null || idPutovanja <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nije moguće dohvatiti ID putovanja.'),
        ),
      );
      return;
    }

    final grad = putovanje['grad']?.toString() ?? 'odabrano putovanje';

    final potvrda = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Obrisati putovanje?'),
        content: Text(
          'Jeste li sigurni da želite obrisati putovanje u $grad? '
          'Brisanjem će se ukloniti i sve njegove aktivnosti i troškovi. '
          'Ovu radnju nije moguće poništiti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (potvrda != true || !mounted) return;

    try {
      await ApiService.obrisiPutovanje(
        token: widget.token,
        idPutovanja: idPutovanja,
      );

      if (!mounted) return;

      setState(ucitajPutovanja);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Putovanje je uspješno obrisano.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void odjava() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ime = widget.user['ime']?.toString() ?? 'putnik';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF247BA0),
        foregroundColor: Colors.white,
        title: const Text(
          'TravelWithUs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: odjava,
            tooltip: 'Odjava',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final rezultat = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => NewTripScreen(
                token: widget.token,
              ),
            ),
          );

          if (rezultat == true && mounted) {
            setState(() {});
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo putovanje'),
      ),

      body: RefreshIndicator(
        onRefresh: osvjezi,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Bok, $ime!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF183B56),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tvoja sljedeća avantura počinje ovdje.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Moja putovanja',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<dynamic>>(
              future: putovanjaFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.cloud_off_outlined,
                            size: 42,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Putovanja se trenutačno ne mogu učitati.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(ucitajPutovanja);
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Pokušaj ponovno'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final putovanja = snapshot.data ?? [];

                if (putovanja.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.luggage_outlined,
                            size: 48,
                            color: Color(0xFF247BA0),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Još nemaš spremljenih putovanja.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: putovanja.map((item) {
                    final p = Map<String, dynamic>.from(item);

                    final grad = p['grad']?.toString() ?? 'Nepoznat grad';
                    final drzava =
                        p['drzava']?.toString() ?? 'Nepoznata država';
                    final budzet =
                        double.tryParse('${p['budzet']}') ?? 0;

                    return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        clipBehavior: Clip.antiAlias,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TripDetailsScreen(
                                  token: widget.token,
                                  putovanje: p,
                                ),
                              ),
                            );
                          },

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 105,
                            color: const Color(0xFF247BA0),
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.flight_takeoff,
                                  color: Colors.white,
                                  size: 38,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        grad,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 23,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        drzava,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      potvrdiBrisanjePutovanja(p),
                                  tooltip: 'Obriši putovanje',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: [
                                _infoRed(
                                  Icons.calendar_month_outlined,
                                  'Polazak',
                                  formatDatum(p['datum_polaska']),
                                ),
                                const SizedBox(height: 14),
                                _infoRed(
                                  Icons.event_available_outlined,
                                  'Povratak',
                                  formatDatum(p['datum_povratka']),
                                ),
                                const SizedBox(height: 14),
                                _infoRed(
                                  Icons.people_outline,
                                  'Broj putnika',
                                  '${p['broj_putnika'] ?? 0}',
                                ),
                                const Divider(height: 28),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.account_balance_wallet_outlined,
                                      color: Color(0xFF247BA0),
                                      size: 26,
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'Planirani budžet',
                                        style: TextStyle(fontSize: 15),
                                      ),
                                    ),
                                    Text(
                                      '${budzet.toStringAsFixed(2)} €',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF247BA0),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
          ),
    );    
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Povuci ekran prema dolje za osvježavanje putovanja.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black45,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRed(IconData icon, String naslov, String vrijednost) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF247BA0), size: 23),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            naslov,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        Text(
          vrijednost,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// DETALJI POJEDINOG PUTOVANJA

class TripDetailsScreen extends StatelessWidget {
  final String token;
  final Map<String, dynamic> putovanje;

  const TripDetailsScreen({
    super.key,
    required this.token,
    required this.putovanje,
  });

  String formatDatum(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'Nije naveden';
    }

    final date = DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}.';
  }

  Widget infoRed(IconData ikona, String naslov, String vrijednost) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(
            ikona,
            color: const Color(0xFF247BA0),
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              naslov,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              vrijednost,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grad = putovanje['grad']?.toString() ?? 'Nepoznat grad';
    final drzava =
        putovanje['drzava']?.toString() ?? 'Nepoznata država';

    final budzet =
        double.tryParse('${putovanje['budzet']}') ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),

      appBar: AppBar(
        backgroundColor: const Color(0xFF247BA0),
        foregroundColor: Colors.white,
        title: const Text('Detalji putovanja'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF247BA0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.flight_takeoff,
                  color: Colors.white,
                  size: 42,
                ),
                const SizedBox(height: 16),

                Text(
                  grad,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  drzava,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Osnovne informacije',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  infoRed(
                    Icons.calendar_month,
                    'Polazak',
                    formatDatum(putovanje['datum_polaska']),
                  ),

                  infoRed(
                    Icons.event_available,
                    'Povratak',
                    formatDatum(putovanje['datum_povratka']),
                  ),

                  infoRed(
                    Icons.people_outline,
                    'Broj putnika',
                    '${putovanje['broj_putnika'] ?? 0}',
                  ),

                  const Divider(),

                  infoRed(
                    Icons.account_balance_wallet_outlined,
                    'Planirani budžet',
                    '${budzet.toStringAsFixed(2)} €',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'Organizacija putovanja',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.event_note),
              ),
              title: const Text('Aktivnosti'),
              subtitle: const Text(
                'Planiraj što želiš posjetiti i raditi.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final idPutovanja = int.tryParse(
                  putovanje['id_putovanja']?.toString() ?? '',
                );

                if (idPutovanja == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nije moguće dohvatiti ID putovanja.'),
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActivitiesScreen(
                      token: token,
                      idPutovanja: idPutovanja,
                    ),
                  ),
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.payments_outlined),
              ),
              title: const Text('Troškovi'),
              subtitle: const Text(
                'Evidentiraj troškove svojeg putovanja.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final idPutovanja = int.tryParse(
                  putovanje['id_putovanja']?.toString() ?? '',
                );

                if (idPutovanja == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nije moguće dohvatiti ID putovanja.'),
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CostsScreen(
                      token: token,
                      idPutovanja: idPutovanja,
                    ),
                  ),
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.account_balance_wallet_outlined),
              ),
              title: const Text('Financijski pregled'),
              subtitle: const Text(
                'Prati budžet i potrošeni novac.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final idPutovanja = int.tryParse(
                  putovanje['id_putovanja']?.toString() ?? '',
                );

                if (idPutovanja == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nije moguće dohvatiti ID putovanja.'),
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FinancialOverviewScreen(
                      token: token,
                      idPutovanja: idPutovanja,
                      budzet: budzet,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


// AKTIVNOSTI ODABRANOG PUTOVANJA
class ActivitiesScreen extends StatefulWidget {
  final String token;
  final int idPutovanja;

  const ActivitiesScreen({
    super.key,
    required this.token,
    required this.idPutovanja,
  });

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  late Future<Map<String, dynamic>> aktivnostiFuture;

  @override
  void initState() {
    super.initState();
    ucitajAktivnosti();
  }

  void ucitajAktivnosti() {
    aktivnostiFuture = ApiService.getAktivnostiPodaci(
      widget.token,
      widget.idPutovanja,
    );
  }

  Future<void> otvoriObrazac({Map<String, dynamic>? aktivnost}) async {
    final podaci = await aktivnostiFuture;
    if (!mounted) return;

    final kategorije = List<Map<String, dynamic>>.from(
      (podaci['kategorije'] as List).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );

    if (kategorije.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nema dostupnih kategorija aktivnosti.'),
        ),
      );
      return;
    }

    final rezultat = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityFormScreen(
          token: widget.token,
          idPutovanja: widget.idPutovanja,
          kategorije: kategorije,
          aktivnost: aktivnost,
        ),
      ),
    );

    if (rezultat == true && mounted) {
      setState(ucitajAktivnosti);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            aktivnost == null
                ? 'Aktivnost je uspješno dodana.'
                : 'Aktivnost je uspješno ažurirana.',
          ),
        ),
      );
    }
  }

  Future<void> obrisiAktivnost(Map<String, dynamic> aktivnost) async {
    final naziv = aktivnost['naziv']?.toString() ?? 'ovu aktivnost';

    final potvrda = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Brisanje aktivnosti'),
        content: Text('Želiš li obrisati aktivnost „$naziv”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Odustani'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (potvrda != true || !mounted) return;

    final idAktivnosti = int.tryParse(
      aktivnost['id_aktivnosti']?.toString() ?? '',
    );

    if (idAktivnosti == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nije moguće pronaći ID aktivnosti.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await ApiService.obrisiAktivnost(
        token: widget.token,
        idAktivnosti: idAktivnosti,
      );

      if (!mounted) return;
      setState(ucitajAktivnosti);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktivnost je uspješno obrisana.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF247BA0),
        foregroundColor: Colors.white,
        title: const Text('Aktivnosti'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => otvoriObrazac(),
        backgroundColor: const Color(0xFF247BA0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj aktivnost'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: aktivnostiFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Aktivnosti se ne mogu učitati.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => setState(ucitajAktivnosti),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Pokušaj ponovno'),
                    ),
                  ],
                ),
              ),
            );
          }

          final podaci = snapshot.data ?? {};
          final aktivnosti = List<dynamic>.from(
            podaci['aktivnosti'] ?? [],
          );

          if (aktivnosti.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: const [
                SizedBox(height: 90),
                Icon(
                  Icons.event_busy_outlined,
                  size: 58,
                  color: Color(0xFF247BA0),
                ),
                SizedBox(height: 14),
                Text(
                  'Još nema dodanih aktivnosti za ovo putovanje.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Pritisni „Dodaj aktivnost” za unos prve aktivnosti.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: aktivnosti.length,
            itemBuilder: (context, index) {
              final aktivnost = Map<String, dynamic>.from(
                aktivnosti[index] as Map,
              );

              final naziv = aktivnost['naziv']?.toString() ?? '';
              final opis = aktivnost['opis']?.toString() ?? '';
              final kategorija =
                  aktivnost['kategorija']?.toString() ?? '';
              final dan = aktivnost['dan']?.toString() ?? '';
              final vrijeme = aktivnost['vrijeme']?.toString() ?? '';
              final trajanje = aktivnost['trajanje']?.toString() ?? '';
              final cijena = aktivnost['cijena']?.toString() ?? '0';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              naziv,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF183B56),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Uredi aktivnost',
                            onPressed: () => otvoriObrazac(
                              aktivnost: aktivnost,
                            ),
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Color(0xFF247BA0),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Obriši aktivnost',
                            onPressed: () => obrisiAktivnost(aktivnost),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (kategorija.isNotEmpty)
                        _activityInfo(Icons.category_outlined, 'Kategorija', kategorija),
                      if (dan.isNotEmpty)
                        _activityInfo(Icons.calendar_today_outlined, 'Dan', dan),
                      if (vrijeme.isNotEmpty)
                        _activityInfo(Icons.access_time, 'Vrijeme', vrijeme),
                      if (trajanje.isNotEmpty)
                        _activityInfo(Icons.timelapse, 'Trajanje', '$trajanje min'),
                      _activityInfo(Icons.euro, 'Cijena', '$cijena €'),
                      if (opis.isNotEmpty) ...[
                        const Divider(height: 22),
                        Text(opis),
                      ],
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

  Widget _activityInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 17, color: const Color(0xFF247BA0)),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.black54)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// OBRAZAC ZA DODAVANJE I UREDIVANJE AKTIVNOSTI
class ActivityFormScreen extends StatefulWidget {
  final String token;
  final int idPutovanja;
  final List<Map<String, dynamic>> kategorije;
  final Map<String, dynamic>? aktivnost;

  const ActivityFormScreen({
    super.key,
    required this.token,
    required this.idPutovanja,
    required this.kategorije,
    this.aktivnost,
  });

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nazivController;
  late final TextEditingController _opisController;
  late final TextEditingController _trajanjeController;
  late final TextEditingController _danController;
  late final TextEditingController _cijenaController;

  int? _idKategorija;
  TimeOfDay _vrijeme = const TimeOfDay(hour: 9, minute: 0);
  bool _spremanje = false;

  bool get _uredivanje => widget.aktivnost != null;

  @override
  void initState() {
    super.initState();
    final a = widget.aktivnost;

    _nazivController = TextEditingController(
      text: a?['naziv']?.toString() ?? '',
    );
    _opisController = TextEditingController(
      text: a?['opis']?.toString() ?? '',
    );
    _trajanjeController = TextEditingController(
      text: a?['trajanje']?.toString() ?? '',
    );
    _danController = TextEditingController(
      text: a?['dan']?.toString() ?? '1',
    );
    _cijenaController = TextEditingController(
      text: a?['cijena']?.toString() ?? '0',
    );

    final idKategorija = int.tryParse(
      a?['id_kategorija']?.toString() ?? '',
    );
    if (idKategorija != null &&
        widget.kategorije.any(
          (k) => int.tryParse(k['id_kategorije'].toString()) == idKategorija,
        )) {
      _idKategorija = idKategorija;
    }

    final vrijeme = a?['vrijeme']?.toString() ?? '';
    final dijeloviVremena = vrijeme.split(':');
    if (dijeloviVremena.length >= 2) {
      final sat = int.tryParse(dijeloviVremena[0]);
      final minuta = int.tryParse(dijeloviVremena[1]);
      if (sat != null && minuta != null && sat >= 0 && sat < 24 && minuta >= 0 && minuta < 60) {
        _vrijeme = TimeOfDay(hour: sat, minute: minuta);
      }
    }
  }

  @override
  void dispose() {
    _nazivController.dispose();
    _opisController.dispose();
    _trajanjeController.dispose();
    _danController.dispose();
    _cijenaController.dispose();
    super.dispose();
  }

  String _formatVrijeme(TimeOfDay vrijeme) {
    return '${vrijeme.hour.toString().padLeft(2, '0')}:'
        '${vrijeme.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _odaberiVrijeme() async {
    final odabrano = await showTimePicker(
      context: context,
      initialTime: _vrijeme,
      helpText: 'Odaberi vrijeme aktivnosti',
      cancelText: 'Odustani',
      confirmText: 'Odaberi',
    );

    if (odabrano != null && mounted) {
      setState(() => _vrijeme = odabrano);
    }
  }

  Future<void> _spremiAktivnost() async {
    if (!_formKey.currentState!.validate()) return;

    if (_idKategorija == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Odaberi kategoriju aktivnosti.')),
      );
      return;
    }

    final trajanje = int.tryParse(_trajanjeController.text.trim());
    final dan = int.tryParse(_danController.text.trim());
    final cijena = double.tryParse(
      _cijenaController.text.trim().replaceAll(',', '.'),
    );

    if (trajanje == null || dan == null || cijena == null) return;

    setState(() => _spremanje = true);

    try {
      if (_uredivanje) {
        final idAktivnosti = int.tryParse(
          widget.aktivnost!['id_aktivnosti']?.toString() ?? '',
        );
        if (idAktivnosti == null) {
          throw Exception('Nije moguće dohvatiti ID aktivnosti.');
        }

        await ApiService.urediAktivnost(
          token: widget.token,
          idAktivnosti: idAktivnosti,
          idPutovanja: widget.idPutovanja,
          naziv: _nazivController.text.trim(),
          opis: _opisController.text.trim(),
          idKategorija: _idKategorija!,
          trajanje: trajanje,
          dan: dan,
          vrijeme: _formatVrijeme(_vrijeme),
          cijena: cijena,
        );
      } else {
        await ApiService.dodajAktivnost(
          token: widget.token,
          idPutovanja: widget.idPutovanja,
          naziv: _nazivController.text.trim(),
          opis: _opisController.text.trim(),
          idKategorija: _idKategorija!,
          trajanje: trajanje,
          dan: dan,
          vrijeme: _formatVrijeme(_vrijeme),
          cijena: cijena,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _spremanje = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF247BA0),
        foregroundColor: Colors.white,
        title: Text(_uredivanje ? 'Uredi aktivnost' : 'Dodaj aktivnost'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _nazivController,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Naziv aktivnosti',
                  prefixIcon: Icon(Icons.event_note),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Unesi naziv aktivnosti.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _opisController,
                maxLength: 500,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Opis',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _idKategorija,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Kategorija',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: widget.kategorije.map((kategorija) {
                  final id = int.parse(kategorija['id_kategorije'].toString());
                  return DropdownMenuItem<int>(
                    value: id,
                    child: Text(kategorija['naziv']?.toString() ?? ''),
                  );
                }).toList(),
                onChanged: _spremanje
                    ? null
                    : (value) => setState(() => _idKategorija = value),
                validator: (value) =>
                    value == null ? 'Odaberi kategoriju.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _danController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Dan putovanja',
                  hintText: 'npr. 1',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final dan = int.tryParse((value ?? '').trim());
                  if (dan == null || dan < 1) {
                    return 'Unesi ispravan dan putovanja.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _spremanje ? null : _odaberiVrijeme,
                icon: const Icon(Icons.access_time),
                label: Text('Vrijeme: ${_formatVrijeme(_vrijeme)}'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _trajanjeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Trajanje (minute)',
                  prefixIcon: Icon(Icons.timelapse),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final trajanje = int.tryParse((value ?? '').trim());
                  if (trajanje == null || trajanje <= 0) {
                    return 'Unesi trajanje u minutama.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cijenaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Cijena (€)',
                  prefixIcon: Icon(Icons.euro),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final cijena = double.tryParse(
                    (value ?? '').trim().replaceAll(',', '.'),
                  );
                  if (cijena == null || !cijena.isFinite || cijena < 0) {
                    return 'Unesi ispravnu cijenu (0 ili više).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _spremanje ? null : _spremiAktivnost,
                  icon: _spremanje
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _spremanje
                        ? 'Spremanje...'
                        : (_uredivanje ? 'Spremi promjene' : 'Dodaj aktivnost'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF247BA0),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// TROŠKOVI ODABRANOG PUTOVANJA
class CostsScreen extends StatefulWidget {
  final String token;
  final int idPutovanja;

  const CostsScreen({
    super.key,
    required this.token,
    required this.idPutovanja,
  });

  @override
  State<CostsScreen> createState() => _CostsScreenState();
}

class _CostsScreenState extends State<CostsScreen> {
  late Future<Map<String, dynamic>> troskoviFuture;

  @override
  void initState() {
    super.initState();
    ucitajTroskove();
  }

  void ucitajTroskove() {
    troskoviFuture = ApiService.getTroskoviPodaci(
      widget.token,
      widget.idPutovanja,
    );
  }

  Future<void> otvoriObrazac({Map<String, dynamic>? trosak}) async {
    try {
      final podaci = await troskoviFuture;
      if (!mounted) return;

      final kategorije = List<Map<String, dynamic>>.from(
        (podaci['kategorije'] as List).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );

      if (kategorije.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nema dostupnih kategorija troškova.')),
        );
        return;
      }

      final rezultat = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => CostFormScreen(
            token: widget.token,
            idPutovanja: widget.idPutovanja,
            kategorije: kategorije,
            trosak: trosak,
          ),
        ),
      );

      if (rezultat == true && mounted) {
        setState(ucitajTroskove);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              trosak == null
                  ? 'Trošak je uspješno dodan.'
                  : 'Trošak je uspješno ažuriran.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> obrisiTrosak(Map<String, dynamic> trosak) async {
    final naziv = trosak['trosak']?.toString() ?? 'ovaj trošak';

    final potvrda = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Brisanje troška'),
        content: Text('Želiš li obrisati trošak „$naziv”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Odustani'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (potvrda != true || !mounted) return;

    final idTroskovi = int.tryParse(
      trosak['id_troskovi']?.toString() ?? '',
    );

    if (idTroskovi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nije moguće pronaći ID troška.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await ApiService.obrisiTrosak(
        token: widget.token,
        idTroskovi: idTroskovi,
      );

      if (!mounted) return;
      setState(ucitajTroskove);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trošak je uspješno obrisan.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  double _iznos(dynamic value) => double.tryParse(value.toString()) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF247BA0),
        foregroundColor: Colors.white,
        title: const Text('Troškovi'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => otvoriObrazac(),
        backgroundColor: const Color(0xFF247BA0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj trošak'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: troskoviFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 42),
                    const SizedBox(height: 12),
                    const Text(
                      'Troškovi se ne mogu učitati.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => setState(ucitajTroskove),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Pokušaj ponovno'),
                    ),
                  ],
                ),
              ),
            );
          }

          final podaci = snapshot.data ?? {};
          final troskovi = List<dynamic>.from(podaci['troskovi'] ?? []);
          final ukupno = _iznos(podaci['ukupno'] ?? 0);

          return RefreshIndicator(
            onRefresh: () async {
              setState(ucitajTroskove);
              await troskoviFuture;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                Card(
                  color: const Color(0xFFE4F2F8),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFF247BA0),
                          foregroundColor: Colors.white,
                          child: Icon(Icons.account_balance_wallet_outlined),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Ukupni troškovi',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Text(
                          '${ukupno.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF183B56),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Evidencija troškova',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (troskovi.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 52, color: Color(0xFF247BA0)),
                          SizedBox(height: 12),
                          Text(
                            'Još nema evidentiranih troškova.',
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Pritisni „Dodaj trošak” za unos prvog troška.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...troskovi.map((item) {
                    final t = Map<String, dynamic>.from(item as Map);
                    final naziv = t['trosak']?.toString() ?? '';
                    final kategorija = t['kategorija']?.toString() ?? '';
                    final opis = t['opis']?.toString() ?? '';
                    final dan = t['dan']?.toString() ?? '';
                    final iznos = _iznos(t['iznos'] ?? 0);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    naziv,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF183B56),
                                    ),
                                  ),
                                ),
                                Text(
                                  '${iznos.toStringAsFixed(2)} €',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF247BA0),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Uredi trošak',
                                  onPressed: () => otvoriObrazac(trosak: t),
                                  icon: const Icon(Icons.edit_outlined,
                                      color: Color(0xFF247BA0)),
                                ),
                                IconButton(
                                  tooltip: 'Obriši trošak',
                                  onPressed: () => obrisiTrosak(t),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            if (kategorija.isNotEmpty)
                              _costInfo(Icons.category_outlined, 'Kategorija', kategorija),
                            if (dan.isNotEmpty)
                              _costInfo(Icons.calendar_today_outlined, 'Dan putovanja', dan),
                            if (opis.isNotEmpty) ...[
                              const Divider(height: 20),
                              Text(opis),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _costInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 17, color: const Color(0xFF247BA0)),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.black54)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// OBRAZAC ZA DODAVANJE I UREĐIVANJE TROŠKA
class CostFormScreen extends StatefulWidget {
  final String token;
  final int idPutovanja;
  final List<Map<String, dynamic>> kategorije;
  final Map<String, dynamic>? trosak;

  const CostFormScreen({
    super.key,
    required this.token,
    required this.idPutovanja,
    required this.kategorije,
    this.trosak,
  });

  @override
  State<CostFormScreen> createState() => _CostFormScreenState();
}

class _CostFormScreenState extends State<CostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _trosakController;
  late final TextEditingController _iznosController;
  late final TextEditingController _opisController;
  late final TextEditingController _danController;
  int? _idVrsteTroska;
  bool _spremanje = false;

  bool get _uredivanje => widget.trosak != null;

  @override
  void initState() {
    super.initState();
    final t = widget.trosak;
    _trosakController = TextEditingController(
      text: t?['trosak']?.toString() ?? '',
    );
    _iznosController = TextEditingController(
      text: t?['iznos']?.toString() ?? '',
    );
    _opisController = TextEditingController(
      text: t?['opis']?.toString() ?? '',
    );
    _danController = TextEditingController(
      text: t?['dan']?.toString() ?? '1',
    );

    final id = int.tryParse(t?['id_vrste_troska']?.toString() ?? '');
    if (id != null &&
        widget.kategorije.any(
          (k) => int.tryParse(k['id_vrste_troska'].toString()) == id,
        )) {
      _idVrsteTroska = id;
    }
  }

  @override
  void dispose() {
    _trosakController.dispose();
    _iznosController.dispose();
    _opisController.dispose();
    _danController.dispose();
    super.dispose();
  }

  Future<void> _spremiTrosak() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idVrsteTroska == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Odaberi kategoriju troška.')),
      );
      return;
    }

    final iznos = double.tryParse(
      _iznosController.text.trim().replaceAll(',', '.'),
    );
    final dan = int.tryParse(_danController.text.trim());
    if (iznos == null || dan == null) return;

    setState(() => _spremanje = true);
    try {
      if (_uredivanje) {
        final idTroskovi = int.tryParse(
          widget.trosak!['id_troskovi']?.toString() ?? '',
        );
        if (idTroskovi == null) {
          throw Exception('Nije moguće dohvatiti ID troška.');
        }
        await ApiService.urediTrosak(
          token: widget.token,
          idTroskovi: idTroskovi,
          idPutovanja: widget.idPutovanja,
          trosak: _trosakController.text.trim(),
          iznos: iznos,
          opis: _opisController.text.trim(),
          dan: dan,
          idVrsteTroska: _idVrsteTroska!,
        );
      } else {
        await ApiService.dodajTrosak(
          token: widget.token,
          idPutovanja: widget.idPutovanja,
          trosak: _trosakController.text.trim(),
          iznos: iznos,
          opis: _opisController.text.trim(),
          dan: dan,
          idVrsteTroska: _idVrsteTroska!,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _spremanje = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF247BA0),
        foregroundColor: Colors.white,
        title: Text(_uredivanje ? 'Uredi trošak' : 'Dodaj trošak'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _trosakController,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Naziv troška',
                  hintText: 'npr. Taxi, ručak, hotel',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Unesi naziv troška.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _iznosController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Iznos (€)',
                  prefixIcon: Icon(Icons.euro),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final iznos = double.tryParse(
                    (value ?? '').trim().replaceAll(',', '.'),
                  );
                  if (iznos == null || !iznos.isFinite || iznos < 0) {
                    return 'Unesi ispravan iznos (0 ili više).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _idVrsteTroska,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Kategorija troška',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: widget.kategorije.map((kategorija) {
                  final id = int.parse(kategorija['id_vrste_troska'].toString());
                  return DropdownMenuItem<int>(
                    value: id,
                    child: Text(kategorija['naziv']?.toString() ?? ''),
                  );
                }).toList(),
                onChanged: _spremanje
                    ? null
                    : (value) => setState(() => _idVrsteTroska = value),
                validator: (value) => value == null ? 'Odaberi kategoriju.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _danController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Dan putovanja',
                  hintText: 'npr. 1',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final dan = int.tryParse((value ?? '').trim());
                  if (dan == null || dan < 1) return 'Unesi ispravan dan putovanja.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _opisController,
                maxLength: 500,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Opis (nije obavezan)',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _spremanje ? null : _spremiTrosak,
                  icon: _spremanje
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _spremanje
                        ? 'Spremanje...'
                        : (_uredivanje ? 'Spremi promjene' : 'Dodaj trošak'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF247BA0),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// FINANCIJSKI PREGLED ODABRANOG PUTOVANJA
class FinancialOverviewScreen extends StatefulWidget {
  final String token;
  final int idPutovanja;
  final double budzet;

  const FinancialOverviewScreen({
    super.key,
    required this.token,
    required this.idPutovanja,
    required this.budzet,
  });

  @override
  State<FinancialOverviewScreen> createState() =>
      _FinancialOverviewScreenState();
}

class _FinancialOverviewScreenState
    extends State<FinancialOverviewScreen> {
  late Future<Map<String, dynamic>> financijeFuture;

  @override
  void initState() {
    super.initState();
    ucitajFinancije();
  }

  void ucitajFinancije() {
    financijeFuture = Future.wait([
      ApiService.getTroskoviPodaci(
        widget.token,
        widget.idPutovanja,
      ),
      ApiService.getAktivnostiPodaci(
        widget.token,
        widget.idPutovanja,
      ),
    ]).then((rezultati) {
      return {
        ...rezultati[0],
        'aktivnosti': rezultati[1]['aktivnosti'] ?? [],
      };
    });
  }

  double _iznos(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatIznos(double value) {
    return '${value.toStringAsFixed(2)} €';
  }

  Map<String, double> _izracunajKategorije(List<dynamic> troskovi) {
    final rezultat = <String, double>{};

    for (final item in troskovi) {
      final trosak = Map<String, dynamic>.from(item as Map);
      final kategorija =
          trosak['kategorija']?.toString().trim().isNotEmpty == true
              ? trosak['kategorija'].toString()
              : 'Ostalo';

      rezultat[kategorija] =
          (rezultat[kategorija] ?? 0) + _iznos(trosak['iznos']);
    }

    return rezultat;
  }

  Color _bojaKategorije(String kategorija) {
    switch (kategorija.toLowerCase()) {
      case 'prijevoz':
        return const Color(0xFF247BA0);
      case 'smještaj':
      case 'smjestaj':
        return const Color(0xFF70A9A1);
      case 'hrana':
        return const Color(0xFFF4A261);
      default:
        return const Color(0xFF8D99AE);
    }
  }

  Widget _financijskaKartica({
    required String naslov,
    required String iznos,
    required IconData ikona,
    required Color boja,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: boja.withValues(alpha: 0.13),
              foregroundColor: boja,
              child: Icon(ikona),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                naslov,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              iznos,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: boja,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF247BA0),
        foregroundColor: Colors.white,
        title: const Text('Financijski pregled'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: financijeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Financijski podaci se ne mogu učitati.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => setState(ucitajFinancije),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Pokušaj ponovno'),
                    ),
                  ],
                ),
              ),
            );
          }

          
            final podaci = snapshot.data ?? {};

            final troskovi = List<dynamic>.from(podaci['troskovi'] ?? []);
            final aktivnosti = List<dynamic>.from(podaci['aktivnosti'] ?? []);

            // Ukupni evidentirani troškovi
            final ukupnoTroskovi = _iznos(podaci['ukupno'] ?? 0);

            // Ukupna cijena svih aktivnosti
            final ukupnoAktivnosti = aktivnosti.fold<double>(
              0.0,
              (suma, item) {
                final aktivnost = Map<String, dynamic>.from(item as Map);
                return suma + _iznos(aktivnost['cijena']);
              },
            );

            // Ukupna potrošnja = troškovi + aktivnosti
            final ukupno = ukupnoTroskovi + ukupnoAktivnosti;

            // Preostali budžet
            final preostalo = widget.budzet - ukupno;

            // Postotak iskorištenog budžeta
            final postotak = widget.budzet > 0
                ? (ukupno / widget.budzet).clamp(0.0, 1.0)
                : 0.0;

            // Troškovi po kategorijama
            final kategorije = _izracunajKategorije(troskovi);

            // Provjera prekoračenja budžeta
            final prekoracenBudzet = ukupno > widget.budzet;


          return RefreshIndicator(
            onRefresh: () async {
              setState(ucitajFinancije);
              await financijeFuture;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: const Color(0xFFE4F2F8),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Color(0xFF247BA0),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Pregled budžeta',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF183B56),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(
                          _formatIznos(preostalo),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: prekoracenBudzet
                                ? Colors.red.shade700
                                : const Color(0xFF183B56),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prekoracenBudzet
                              ? 'Budžet je premašen'
                              : 'Preostalo od planiranog budžeta',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: postotak,
                            minHeight: 12,
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              prekoracenBudzet
                                  ? Colors.red
                                  : const Color(0xFF247BA0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${(widget.budzet > 0 ? ukupno / widget.budzet * 100 : 0).toStringAsFixed(1)} % budžeta iskorišteno',
                          style: const TextStyle(
                            color: Color(0xFF183B56),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _financijskaKartica(
                  naslov: 'Planirani budžet',
                  iznos: _formatIznos(widget.budzet),
                  ikona: Icons.savings_outlined,
                  boja: const Color(0xFF247BA0),
                ),
                _financijskaKartica(
                  naslov: 'Troškovi',
                  iznos: _formatIznos(ukupnoTroskovi),
                  ikona: Icons.receipt_long_outlined,
                  boja: const Color(0xFF247BA0),
                ),
                _financijskaKartica(
                  naslov: 'Aktivnosti',
                  iznos: _formatIznos(ukupnoAktivnosti),
                  ikona: Icons.event_available_outlined,
                  boja: const Color(0xFFF4A261),
                ),
                _financijskaKartica(
                  naslov: 'Ukupno potrošeno',
                  iznos: _formatIznos(ukupno),
                  ikona: Icons.payments_outlined,
                  boja: const Color(0xFFE07A5F),
                ),
                _financijskaKartica(
                  naslov: prekoracenBudzet
                      ? 'Iznos iznad budžeta'
                      : 'Preostali budžet',
                  iznos: _formatIznos(preostalo.abs()),
                  ikona: prekoracenBudzet
                      ? Icons.warning_amber_outlined
                      : Icons.account_balance_wallet_outlined,
                  boja: prekoracenBudzet
                      ? Colors.red.shade700
                      : const Color(0xFF3A7D44),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Troškovi po kategorijama',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF183B56),
                  ),
                ),
                const SizedBox(height: 10),
                if (kategorije.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(22),
                      child: Column(
                        children: [
                          Icon(
                            Icons.pie_chart_outline,
                            size: 48,
                            color: Color(0xFF247BA0),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Još nema evidentiranih troškova.',
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Dodani troškovi prikazat će se po kategorijama.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: kategorije.entries.map((entry) {
                          final udio = ukupnoTroskovi > 0
                              ? (entry.value / ukupnoTroskovi).clamp(0.0, 1.0)
                              : 0.0;
                          final boja = _bojaKategorije(entry.key);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: boja,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatIznos(entry.value),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: udio,
                                    minHeight: 9,
                                    backgroundColor: const Color(0xFFE9EEF2),
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(boja),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(udio * 100).toStringAsFixed(1)} % ukupnih troškova',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Povuci ekran prema dolje za osvježavanje financijskih podataka.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


class NewTripScreen extends StatefulWidget {
  final String token;

  const NewTripScreen({
    super.key,
    required this.token,
  });

  @override
  State<NewTripScreen> createState() => _NewTripScreenState();
}

class _NewTripScreenState extends State<NewTripScreen> {
  final _formKey = GlobalKey<FormState>();

  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _budgetController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime? _departureDate;
  DateTime? _returnDate;

  int _passengers = 1;
  bool _saving = false;

  Future<void> _selectDate(bool isDeparture) async {
    final today = DateTime.now();

    final initialDate = isDeparture
        ? (_departureDate ?? today)
        : (_returnDate ??
            _departureDate ??
            today.add(const Duration(days: 1)));

    final firstDate = isDeparture
        ? DateTime(today.year, today.month, today.day)
        : (_departureDate ?? today);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate)
          ? firstDate
          : initialDate,
      firstDate: firstDate,
      lastDate: DateTime(today.year + 10),
      helpText: isDeparture
          ? 'Odaberi datum polaska'
          : 'Odaberi datum povratka',
      cancelText: 'Odustani',
      confirmText: 'Odaberi',
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (isDeparture) {
        _departureDate = picked;

        if (_returnDate != null &&
            _returnDate!.isBefore(picked)) {
          _returnDate = null;
        }
      } else {
        _returnDate = picked;
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Odaberi datum';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}.';
  }

  String _apiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;

    if (_departureDate == null || _returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Odaberi datum polaska i povratka.'),
        ),
      );
      return;
    }

    if (_returnDate!.isBefore(_departureDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Datum povratka ne može biti prije polaska.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final uri = Uri.parse(
        '${ApiService.baseUrl}/novo_putovanje.php',
      );

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'drzava': _countryController.text.trim(),
          'grad': _cityController.text.trim(),
          'datum_polaska': _apiDate(_departureDate!),
          'datum_povratka': _apiDate(_returnDate!),
          'broj_putnika': _passengers,
          'budzet': double.parse(
            _budgetController.text.trim().replaceAll(',', '.'),
          ),
          'napomena': _noteController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201 &&
          data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Putovanje je uspješno spremljeno!'),
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? 'Spremanje nije uspjelo.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška pri povezivanju s API-jem: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _countryController.dispose();
    _cityController.dispose();
    _budgetController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo putovanje'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Isplaniraj svoje sljedeće putovanje!',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Unesi osnovne podatke o putovanju.',
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Država',
                  hintText: 'npr. Hrvatska',
                  prefixIcon: Icon(Icons.public),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Unesi državu.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Grad',
                  hintText: 'npr. Zagreb',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Unesi grad.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () => _selectDate(true),
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  'Polazak: ${_formatDate(_departureDate)}',
                ),
              ),
              const SizedBox(height: 8),

              OutlinedButton.icon(
                onPressed: () => _selectDate(false),
                icon: const Icon(Icons.event_available),
                label: Text(
                  'Povratak: ${_formatDate(_returnDate)}',
                ),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<int>(
                initialValue: _passengers,
                decoration: const InputDecoration(
                  labelText: 'Broj putnika',
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                ),
                items: List.generate(
                  20,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _passengers = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _budgetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Budžet (€)',
                  hintText: 'npr. 250',
                  prefixIcon: Icon(Icons.euro),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final amount = double.tryParse(
                    (value ?? '').trim().replaceAll(',', '.'),
                  );

                  if (amount == null ||
                      !amount.isFinite ||
                      amount < 0) {
                    return 'Unesi valjan budžet.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _noteController,
                maxLines: 3,
                maxLength: 5000,
                decoration: const InputDecoration(
                  labelText: 'Napomena (nije obavezna)',
                  hintText: 'Što želiš zapamtiti za ovo putovanje?',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _saving ? null : _saveTrip,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _saving
                      ? 'Spremanje...'
                      : 'Spremi putovanje',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
