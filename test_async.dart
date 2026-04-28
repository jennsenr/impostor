void main() async {
  try {
    throwSync();
  } finally {
    print("FINALLY EXECUTED");
  }
}

Future<void> throwSync() async {
  print("START ASYNC");
  throw Exception("BOOM");
}
