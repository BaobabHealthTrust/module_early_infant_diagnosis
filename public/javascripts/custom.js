/*
 * Custom javascript code goes in here.
 *
 **/

var checkStatus = false
var coStatus = ""

function dateLimit(str){

    try{ 
        var id = str.split("|")[0];
        var limit = str.split("|")[1];
        if (limit.toLowerCase().trim() == "unknown"){
            
        }else{
           
            $(id).setAttribute("absoluteMin", limit);
        }
    }catch(ex){
        
    }
}

function checkTimeForStoppingBreastFeeding(){
    if(__$("touchscreenInput" + tstCurrentPage).value.trim().toLowerCase() == "Breastfeeding stopped over 6 weeks ago".trim().toLowerCase()){
        showMessage("Confirm HIV status!");

        return;
    } else if(__$("touchscreenInput" + tstCurrentPage).value.trim().toLowerCase() == "Breastfeeding stopped in last 6 weeks".trim().toLowerCase()){
        showMessage("Book HIV test!");

        return;
    }
    setTimeout("checkTimeForStoppingBreastFeeding()", 100)
}

function checkConfirmationStatus(status){
    try{
        if (status){
            conStatus = status
        }
    }catch(dd){

    }
    try{
        if(__$("touchscreenInput" + tstCurrentPage).value.trim().toLowerCase() == conStatus.trim().toLowerCase()){
            showCategory("START ART!");

            return;
        }
    }catch(c){}
    setTimeout("checkConfirmationStatus()", 100)
}

function setHIVStatusCheck(){
    if(__$("1.1.4").value.trim().toLowerCase() == "positive"){
        checkStatus = true;

        checkHIVStatus();
    }
}

function checkHIVStatus(){
    if(__$("touchscreenInput" + tstCurrentPage).value.trim().toLowerCase() == "confirmed"){
        showMessage("START ART");
        checkStatus = false;
    }

    if(checkStatus)
        setTimeout("checkHIVStatus()", 100);
}

function unSetHIVStatus(){
    checkStatus = false;
}

function checkWasting(){
    
}