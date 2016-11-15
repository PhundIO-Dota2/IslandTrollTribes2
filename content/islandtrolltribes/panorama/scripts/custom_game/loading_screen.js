var transition_time = 2
var time_per_tip = 20
var count = CountTips();
var currentTip = -1;
$.Msg(count+1+" Tips Loaded")

function ShowTips(){
    var random_number = Math.floor(Math.random() * count);

    // Random again if the number is the same
    var i = 0;
    while (random_number == currentTip) {
      random_number = Math.floor(Math.random() * count);
      i++;
      if (i > 50) {
          break;
      }
    }

    // accepted random localized string;
    currentTip = random_number
    var str = $.Localize("loading_screen_tip_"+random_number);
    var tip = $("#Tip")
    tip.text = str;
    tip.RemoveClass("Hide")
    tip.AddClass("Show")

    $.Schedule(time_per_tip, function(){
        tip.RemoveClass("Show")
        tip.AddClass("Hide")
    })

    $.Schedule(time_per_tip+transition_time, ShowTips)
};

function CountTips(){
    for(i=0;;i++)
    {
        var tip = $.Localize("loading_screen_tip_"+(i+1))
        if (tip == "loading_screen_tip_"+(i+1)){
            return i;
            break;
        };
    };
};

(function () {
    ShowTips()
})();
