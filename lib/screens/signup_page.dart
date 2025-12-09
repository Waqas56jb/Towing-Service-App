import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _passwordError;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String selectedRole = "User"; // 👈 New: stores selected toggle option

  bool _validateName(String name) {
    if (name.isEmpty) {
      setState(() {
        _nameError = "Name cannot be empty";
      });
      return false;
    }

    RegExp nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegex.hasMatch(name)) {
      setState(() {
        _nameError = "Name should contain only letters";
      });
      return false;
    }

    setState(() {
      _nameError = null;
    });
    return true;
  }

  bool _validateEmail(String email) {
    if (email.isEmpty) {
      setState(() {
        _emailError = "Email cannot be empty";
      });
      return false;
    }

    RegExp emailRegex = RegExp(r'^[a-zA-Z]+[a-zA-Z0-9]*@gmail\.com$');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _emailError = "Email must be in format: name@gmail.com";
      });
      return false;
    }

    setState(() {
      _emailError = null;
    });
    return true;
  }

  bool _validatePassword(String password) {
    if (password.isEmpty) {
      setState(() {
        _passwordError = "Password cannot be empty";
      });
      return false;
    }

    if (password.length < 6) {
      setState(() {
        _passwordError = "Password should be at least 6 characters";
      });
      return false;
    }

    setState(() {
      _passwordError = null;
    });
    return true;
  }

  Future<void> _signUp() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    bool isValidName = _validateName(name);
    bool isValidEmail = _validateEmail(email);
    bool isValidPassword = _validatePassword(password);

    if (isValidName && isValidEmail && isValidPassword) {
      try {
        await _auth
            .createUserWithEmailAndPassword(email: email, password: password);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Signup successful!")));

        // You can now store `selectedRole` in Firestore if needed
      } catch (e) {
        _showError(e.toString());
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 9, 4, 34),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: CustomPaint(
                size: const Size(200, 200),
                painter: CurvedShapePainter(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Signup',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Please signup to continue.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 👇 Toggle Buttons
                    Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          buildToggleButton("User"),
                          buildToggleButton("Mechanic"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Full name',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                        errorText: _nameError,
                        errorStyle: const TextStyle(color: Colors.redAccent),
                      ),
                      onChanged: (value) {
                        _validateName(value);
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Email address',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(
                          Icons.email,
                          color: Colors.white,
                        ),
                        errorText: _emailError,
                        errorStyle: const TextStyle(color: Colors.redAccent),
                      ),
                      onChanged: (value) {
                        _validateEmail(value);
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.lock, color: Colors.white),
                        suffixIcon: const Icon(
                          Icons.visibility_off,
                          color: Colors.white,
                        ),
                        errorText: _passwordError,
                        errorStyle: const TextStyle(color: Colors.redAccent),
                      ),
                      onChanged: (value) {
                        _validatePassword(value);
                      },
                    ),
                    const SizedBox(height: 90),
                    Center(
                      child: Container(
                        width: 251,
                        height: 56.23,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: const Color.fromARGB(255, 159, 123, 255),
                            width: 2,
                          ),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          onPressed: _signUp,
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 159, 123, 255),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              color: Color.fromARGB(255, 159, 123, 255),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildToggleButton(String role) {
    bool isSelected = selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedRole = role;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? const Color.fromARGB(255, 159, 123, 255)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(
            role,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// Dummy painter class for curved shape
class CurvedShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color.fromARGB(80, 159, 123, 255)
          ..style = PaintingStyle.fill;

    final path =
        Path()
          ..lineTo(0, 0)
          ..quadraticBezierTo(size.width / 2, size.height, size.width, 0)
          ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
