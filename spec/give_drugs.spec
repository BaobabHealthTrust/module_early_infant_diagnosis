P.1. Dispensing [program: EARLY INFANT DIAGNOSIS PROGRAM, label: Give drugs, includejs: dispense;generics, includecss: dispense;drug-style, pos: 1]
C.1.1. Given a diagnised patient, Give Drugs

Q.1.1.1. Treatment [optional: true, tt_onLoad: generateGenerics(<%= @patient.id %>); showCategory("Give Drugs"); __$("category").style.fontSize = "30px";  tt_onUnLoad: removeGenerics(), tt_pageStyleClass: NoControls, pos: 0]
