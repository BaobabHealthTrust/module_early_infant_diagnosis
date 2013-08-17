/*
 * Custom javascript code goes in here.
 *
 **/

var checkStatus = false;

function dateLimit(str){

    try{ 
        var id = str.split("|")[0];
        var limit = str.split("|")[1].trim();
        if (limit.toLowerCase().trim() == "unknown"){
            
        }else{           
            $(id).setAttribute("min", limit);
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
    if(__$("touchscreenInput" + tstCurrentPage).value.trim().toLowerCase() == status.trim().toLowerCase()){
        showMessage("START ART!");

        return;
    }
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