// Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2019-2021 Datadog, Inc.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'log_decoder.dart';
import '../common.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('test logging scenario', (WidgetTester tester) async {
    await openTestScenario(tester, 'Logging Scenario');

    var logs = <LogDecoder>[];

    await mockHttpServer!.pollRequests(
      const Duration(seconds: 30),
      (requests) {
        requests
            .map((e) => (e.jsonData as List))
            .expand((e) => e)
            .forEach((e) => logs.add(LogDecoder(e as Map<String, dynamic>)));

        return logs.length >= 4;
      },
    );
    expect(logs.length, greaterThanOrEqualTo(4));

    expect(logs[0].status, 'debug');
    expect(logs[0].message, 'debug message');
    expect(logs[0].tags, contains('tag1:tag-value'));
    expect(logs[0].tags, contains('my-tag'));
    expect(logs[0].log['stringAttribute'], 'string');

    expect(logs[1].status, 'info');
    expect(logs[1].message, 'info message');
    expect(logs[1].tags, isNot(contains('my-tag')));
    expect(logs[1].tags, contains('tag1:tag-value'));
    expect(logs[1].log['nestedAttribute'], containsPair('internal', 'test'));
    expect(logs[1].log['nestedAttribute'], containsPair('isValid', true));

    expect(logs[2].status, 'warn');
    expect(logs[2].message, 'warn message');
    expect(logs[2].tags, isNot(contains('my-tag')));
    expect(logs[2].tags, contains('tag1:tag-value'));
    expect(logs[2].log['doubleAttribute'], 10.34);

    expect(logs[3].status, 'error');
    expect(logs[3].message, 'error message');
    expect(logs[3].tags, isNot(contains('my-tag')));
    expect(logs[3].tags, isNot(contains('tag1:tag-value')));
    expect(logs[3].log['attribute'], 'value');

    for (final log in logs) {
      if (log.log.containsKey('logger-attribute1')) {
        expect(log.log['logger-attribute1'], 'string value');
      }
      // All logs should have logger-attribute2
      expect(log.log['logger-attribute2'], 1000);

      expect(log.serviceName,
          equalsIgnoringCase('com.datadoghq.flutter.integrationtestapp'));

      if (Platform.isIOS) {
        expect(log.threadName, 'main');
      }
    }
  });
}
