import 'package:flutter/material.dart';

/// Navigator raiz do app — usado para abrir a pré-visualização de share
/// mesmo quando o MainShell está a meio de um ciclo de resume.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
