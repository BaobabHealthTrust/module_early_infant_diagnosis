P.1. EID VISIT [program: EARLY INFANT DIAGNOSIS PROGRAM, scope: TODAY, concept: Weight]
C.1. Given an enrolled exposed child under 24 months, when they come for a visit, 	capture the following data:
Q.1.1. Visit date [pos: 0, field_type: date, tt_onLoad: showCategory("EID Visit"), condition: false, value: <%= session["datetime"].to_date rescue Date.today%>]

Q.1.3. Height (cm) [helpText: Baby height (cm), pos: 2, min: 15, max: 120, tt_onLoad: showCategory("EID Visit"), absoluteMin: 15, absoluteMax: 160,  field_type: number, tt_pageStyleClass: NumbersOnlyWithUnknown]

Q.1.4. Weight (grams) [helptext: Baby weight (grams), concept: weight, pos: 3, min: 2500, absoluteMin: 100, max: 10000, absoluteMax: 30000, field_type: number, tt_pageStyleClass: NumbersOnlyWithUnknown]

Q.1.5. MUAC [helpText: Mid Upper Arm Circumference (cm), pos: 4, field_type: number, absoluteMax: 200, absoluteMin: 5, tt_pageStyleClass: NumbersOnlyWithUnknown, tt_onLoad: checkWasting()]

C.1.6. Based on weight/height or MUAC, determine if child is wasting or malnourished. Possible states are:
C.1.6.1. No
C.1.6.2. Moderate
C.1.6.3. Severe

Q.1.7. Breast feeding [pos: 5, helpText: Is Mother Breast Feeding?]
O.1.7.1. Yes
Q.1.7.1.1. Infant Feeding Method [pos: 6]
O.1.7.1.1.1. Breastfed exclusively
O.1.7.1.1.2. Mixed feeding
O.1.7.1.1.3. Breastfeeding complimentary
O.1.7.2. No
Q.1.7.2.1. When was breast feeding stopped? [pos: 7, tt_onUnLoad: if(__$("1.7.2.1").value == "Breastfeeding stopped over 6 weeks ago"){checkTimeForStoppingBreastFeeding()}]
O.1.7.2.1.1. Breastfeeding stopped in last 6 weeks
O.1.7.2.1.2. Breastfeeding stopped over 6 weeks ago


Q.1.8. Is mother on ART? [pos: 10]
O.1.8.1. No ART
O.1.8.2. On ART
O.1.8.3. Died
O.1.8.4. Unknown

Q.1.9. TB status [pos: 11, helpText: Current TB Status of Child]
O.1.9.1. TB suspected
O.1.9.2. Confirmed TB on treatment
O.1.9.3. Confirmed TB NOT on treatment
O.1.9.4. TB NOT suspected
O.1.9.5. Unknown

Q.1.10. Any abnormalities [pos: 12]
O.1.10.1. No
O.1.10.2. Yes
Q.1.10.2.1. Specify abnormalities [pos: 13, concept: Specify]
[
Q.1.11. Childs current HIV status [pos: 14, helpText: Current HIV Status of Child]
O.1.11.1. Confirmed
Q.1.11.1.1. Confirmed [pos: 15, helpText: Confirmation Status, onchange: checkConfirmationStatus("HIV infected"), tt_onLoad: checkConfirmationStatus("HIV infected")]
O.1.11.1.1.1. Not HIV infected
O.1.11.1.1.2. HIV infected
O.1.11.2. Not confirmed
Q.1.11.2.1. Not confirmed [pos: 16, helpText: Non-Confirmation Status,  tt_onLoad: checkConfirmationStatus("Presumed Severe HIV Disease")]
O.1.11.2.1.1. Not ART eligible
O.1.11.2.1.2. Presumed Severe HIV Disease

Q.1.12.1. Allergic to sulphur [helpText: Is Child Allergic to Sulphur?, pos: 17, condition: <%= @patient.allergic_to_sulphur.downcase == "unknown" %>, value: <%= @patient.allergic_to_sulphur.titleize %>]
O.1.12.1.1. Yes
O.1.12.1.2. No
0.1.12.1.3. Unknown

Q.1.13. Outcome [tt_onLoad: __$("category").style.display = "none", pos: 19]
O.1.13.1. Continue follow-up
O.1.13.2. Discharged uninfected
O.1.13.3. ART started
O.1.13.4. Transfer out
O.1.13.5. Defaulted
O.1.13.6. Died

Q.1.14. Next appointment date [pos: 20, concept: Appointment date, tt_onLoad: showCategory("Next Appointment Date"), tt_BeforeUnload: try{__$("category").style.display = "none"}catch(ee){}, field_type: calendar, value: <%= Date.today %>]

