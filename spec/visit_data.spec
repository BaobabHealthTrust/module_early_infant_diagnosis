P.1. EID VISIT [program: EARLY INFANT DIAGNOSIS PROGRAM, scope: TODAY]
C.1. Given an enrolled exposed child under 24 months, when they come for a visit, 	capture the following data:
Q.1.1. Visit date [pos: 0, field_type: date]

Q.1.2. Current age (yrs) [pos: 1, concept: Age, field_type: number, tt_pageStyleClass: NumbersOnlyWithUnknown]

Q.1.3. Height (cm) [pos: 2, field_type: number, tt_pageStyleClass: NumbersOnlyWithUnknown]

Q.1.4. Weight [pos: 3, field_type: number, tt_pageStyleClass: NumbersOnlyWithUnknown]

Q.1.5. MUAC [pos: 4, field_type: number, tt_pageStyleClass: NumbersOnlyWithUnknown, tt_onLoad: checkWasting()]

C.1.6. Based on weight/height or MUAC, determine if child is wasting or 	malnourished. Possible states are:
C.1.6.1. No
C.1.6.2. Moderate
C.1.6.3. Severe

Q.1.7. Breast feeding [pos: 5]
O.1.7.1. Yes
Q.1.7.1.1. Infant feeding method [pos: 6]
O.1.7.1.1.1. Breastfed exclusively
O.1.7.1.1.2. Mixed feeding
O.1.7.1.1.3. Breastfeeding complimentary
O.1.7.2. No
Q.1.7.2.1. When was breast feeding stopped? [pos: 7, tt_onUnLoad: if(__$("touchscreenInput" + tstCurrentPage).value == "Breastfeeding stopped over 6 weeks ago"){__$("1.7.2.1.2.1").name = ""}, tt_onLoad: checkTimeForStoppingBreastFeeding()]
O.1.7.2.1.1. Breastfeeding stopped in last 6 weeks
Q.1.7.2.1.1.1. Appointment date to confirm HIV status [pos: 8, concept: HIV test appointement date, field_type: calendar, value: <%= Date.today %>, tt_onLoad: showCategory("HIV test Appoint. Date")]
O.1.7.2.1.2. Breastfeeding stopped over 6 weeks ago
C.1.7.2.1.2.1. Next URL [pos: 9, name: next_url, type: hidden, value: /protocol_patients/rapid_antibody_test?user_id=<%= @user.id %>&patient_id=<%= @patient.id %>]

Q.1.8. Is mother on ART? [pos: 10]
O.1.8.1. No ART
O.1.8.2. On ART
O.1.8.3. Died
O.1.8.4. Unknown

Q.1.9. TB status [pos: 11]
O.1.9.1. TB suspected
O.1.9.2. Confirmed TB on treatment
O.1.9.3. Confirmed TB NOT on treatment
O.1.9.4. TB NOT suspected
O.1.9.5. Unknown

Q.1.10. Any abnormalities [pos: 12]
O.1.10.1. No
O.1.10.2. Yes
Q.1.10.2.1. Specify abnormalities [pos: 13, concept: Specify]

Q.1.11. Childs current HIV status [pos: 14]
O.1.11.1. Confirmed
Q.1.11.1.1. Confirmed [pos: 15, tt_onLoad: checkConfirmationStatus("HIV infected")]
O.1.11.1.1.1. Not HIV infected
O.1.11.1.1.2. HIV infected
O.1.11.2. Not confirmed
Q.1.11.2.1. Not confirmed [pos: 16, tt_onLoad: checkConfirmationStatus("Presumed Severe HIV Disease")]
O.1.11.2.1.1. Not ART eligible
O.1.11.2.1.2. Presumed Severe HIV Disease

Q.1.12.1. Allergic to sulphur [pos: 17, condition: <%= @patient.allergic_to_sulphur.downcase != "unknown" %>, value: <%= @patient.allergic_to_sulphur.titleize %>]
O.1.12.1.1. Yes
O.1.12.1.2. No
0.1.12.1.3. Unknown

C.1.12. Number of CPT tablets dispensed

Q.1.13. Outcome [pos: 18]
O.1.13.1. Continue follow-up
O.1.13.2. Discharged uninfected
O.1.13.3. ART started
O.1.13.4. Transfer out
O.1.13.5. Defaulted
O.1.13.6. Died

Q.1.14. Next appointment date [pos: 19, concept: Appointment date, tt_onLoad: showCategory("Next Appointment Date"), field_type: calendar, value: <%= Date.today %>]

