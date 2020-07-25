<?php
    /*
        PlayersMap v1.0
        https://www.github.com/PlayersMapAMXX/
    */

    $DB_Server = "-";
    $DB_Username = "-";
    $DB_Password = '-';
    $DB_Port = "-";

    $DB = mysqli_connect($DB_Server, $DB_Username, $DB_Password, "einsdatabase");

    $QueryResult = $DB->query("select * from players");
    $Data = array();

    while ($Entry = $QueryResult->fetch_assoc())
    {
        array_push($Data, $Entry);
    }

    $DataJSON = json_encode($Data);
    $DataJSON = str_replace(['[', ']'], '', $DataJSON);

    mysqli_close($DB);
?>

<style>
    body
    {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica,
            Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
    }
    #chartdiv
    {
        width: 100%;
        height: 97vh;
    }
</style>

<script src="//cdn.amcharts.com/lib/4/core.js"></script>
<script src="//cdn.amcharts.com/lib/4/maps.js"></script>
<script src="//cdn.amcharts.com/lib/4/themes/animated.js"></script>
<script src="//cdn.amcharts.com/lib/4/geodata/worldLow.js"></script>

<div id="chartdiv"></div>

<script>
    am4core.useTheme(am4themes_animated);

    var chart = am4core.create("chartdiv", am4maps.MapChart);
    chart.hiddenState.properties.opacity = 0; // this creates initial fade-in

    chart.geodata = am4geodata_worldLow;
    chart.projection = new am4maps.projections.Miller();

    var title = chart.chartContainer.createChild(am4core.Label);
    title.text = "Players playing in our server";
    title.fontSize = 20;
    title.paddingTop = 30;
    title.align = "center";
    title.zIndex = 100;

    var polygonSeries = chart.series.push(new am4maps.MapPolygonSeries());
    var polygonTemplate = polygonSeries.mapPolygons.template;
    polygonTemplate.tooltipText = "{name}: {value.value.formatNumber('#.0')}";
    polygonSeries.heatRules.push({
        property: "fill",
        target: polygonSeries.mapPolygons.template,
        min: am4core.color("#FFB6C1"),
        max: am4core.color("#FF0000")
    });
    polygonSeries.useGeodata = true;


    polygonSeries.mapPolygons.template.strokeOpacity = 0.4;

    chart.zoomControl = new am4maps.ZoomControl();
    chart.zoomControl.valign = "top";
    
    polygonSeries.exclude = ["AQ"];
    polygonSeries.data = [
        <?php
            echo($DataJSON);
        ?>
    ];
</script>

<body>
    <div id="chartdiv"></div>
</body>
