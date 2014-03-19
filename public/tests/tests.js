var assert = chai.assert;

suite('Analizador Descendente Recursivo Predictivo', function() {
    test('Asignacion y Suma: ', function() {
		 original.value =  "a = 2+3";
		 var esperado = '[\n  {\n    "type": "=",\n    "left": {\n      "type": "ID",\n      "value": "a"\n    },\n    "right": {\n      "type": "+",\n      "left": {\n        "type": "NUM",\n        "value": 2\n      },\n      "right": {\n        "type": "NUM",\n        "value": 3\n      }\n    }\n  }\n]';
		 main ();
       assert.deepEqual(OUTPUT.innerHTML, esperado);
    });
	 test('Statements: ', function() {
		 original.value =  "a = 4*2; b = 2*(a+1); p b";
		 var esperado = '[\n  [\n    {\n      "type": "=",\n      "left": {\n        "type": "ID",\n        "value": "a"\n      },\n      "right": {\n        "type": "*",\n        "left": {\n          "type": "NUM",\n          "value": 4\n        },\n        "right": {\n          "type": "NUM",\n          "value": 2\n        }\n      }\n    }\n  ],\n  {\n    "type": "=",\n    "left": {\n      "type": "ID",\n      "value": "b"\n    },\n    "right": {\n      "type": "*",\n      "left": {\n        "type": "NUM",\n        "value": 2\n      },\n      "right": {\n        "type": "+",\n        "left": {\n          "type": "ID",\n          "value": "a"\n        },\n        "right": {\n          "type": "NUM",\n          "value": 1\n        }\n      }\n    }\n  },\n  {\n    "type": "P",\n    "value": {\n      "type": "ID",\n      "value": "b"\n    }\n  }\n]';
		 main ();
       assert.deepEqual(OUTPUT.innerHTML, esperado);
    });
	 test('Begin: ', function() {
		 original.value =  "begin a = 4*2; b = 5*2 end";
		 var esperado = '[\n  {\n    "type": "BEGIN",\n    "left": [\n      [\n        {\n          "type": "=",\n          "left": {\n            "type": "ID",\n            "value": "a"\n          },\n          "right": {\n            "type": "*",\n            "left": {\n              "type": "NUM",\n              "value": 4\n            },\n            "right": {\n              "type": "NUM",\n              "value": 2\n            }\n          }\n        }\n      ],\n      {\n        "type": "=",\n        "left": {\n          "type": "ID",\n          "value": "b"\n        },\n        "right": {\n          "type": "*",\n          "left": {\n            "type": "NUM",\n            "value": 5\n          },\n          "right": {\n            "type": "NUM",\n            "value": 2\n          }\n        }\n      }\n    ]\n  }\n]';
		 main ();
       assert.deepEqual(OUTPUT.innerHTML, esperado);
    });
	 test('If then: ', function() {
		 original.value =  "a = 4*2; if a > 6 then p a";
		 var esperado = '[\n  [\n    {\n      "type": "=",\n      "left": {\n        "type": "ID",\n        "value": "a"\n      },\n      "right": {\n        "type": "*",\n        "left": {\n          "type": "NUM",\n          "value": 4\n        },\n        "right": {\n          "type": "NUM",\n          "value": 2\n        }\n      }\n    }\n  ],\n  {\n    "type": "IF",\n    "left": {\n      "type": "&gt;",\n      "left": {\n        "type": "ID",\n        "value": "a"\n      },\n      "right": {\n        "type": "NUM",\n        "value": 6\n      }\n    },\n    "right": {\n      "type": "P",\n      "value": {\n        "type": "ID",\n        "value": "a"\n      }\n    }\n  }\n]';
		 main ();
       assert.deepEqual(OUTPUT.innerHTML, esperado);
    });
	 test('While do: ', function() {
		 original.value =  "while a != 1 do b = 4";
		 var esperado = '[\n  {\n    "type": "WHILE",\n    "left": {\n      "type": "!=",\n      "left": {\n        "type": "ID",\n        "value": "a"\n      },\n      "right": {\n        "type": "NUM",\n        "value": 1\n      }\n    },\n    "right": {\n      "type": "=",\n      "left": {\n        "type": "ID",\n        "value": "b"\n      },\n      "right": {\n        "type": "NUM",\n        "value": 4\n      }\n    }\n  }\n]';
		 main ();
       assert.deepEqual(OUTPUT.innerHTML, esperado);
    });
	 test('Error: ', function() {
		 original.value =  "a = 3 + (4; b = 5";
		 main ();
       assert.match(OUTPUT.innerHTML, /Error/);
    });
});