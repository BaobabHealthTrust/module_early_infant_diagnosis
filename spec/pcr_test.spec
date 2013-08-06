P.1. DNA-PCR TEST [program: EARLY INFANT DIAGNOSIS PROGRAM, scope: RECENT, concept: DNA-PCR Testing Result]
C.1.1. Given an exposed, when the child is being enrolled:
Q.1.1.1. DNA-PCR Sample Date, [pos: 0, field_type: date, concept: DNA-PCR Testing Sample Date,  absoluteMin: <%= @patient.person.birthdate%>, helpText: DNA-PCR Sample Date, field_type: date, tt_onLoad: showCategory("DNA-PCR Test")]

Q.1.1.2. DNA-PCR Sample ID [pos: 1, concept: DNA-PCR Testing Sample ID, helpText: DNA-PCR Sample ID]

Q.1.1.3. Date DNA-PCR Result Received [pos: 2, concept: DNA-PCR Testing Result received Date,  absoluteMin: <%= @patient.person.birthdate%>, field_type: date, helpText: Date DNA-PCR Result Received]

Q.1.1.4. DNA-PCR Result [pos: 3, concept: DNA-PCR Testing Result, helpText: DNA-PCR result]
O.1.1.4.1. Negative
O.1.1.4.2. Positive

Q.1.1.5. Date DNA-PCR Result Given [pos: 4, concept: DNA-PCR Testing Result given Date,  absoluteMin: <%= @patient.person.birthdate%>, field_type: date, helpText: Date DNA-PCR Result Given]
