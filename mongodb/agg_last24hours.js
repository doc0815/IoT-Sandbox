[
{$match: {
  sensorTimestamp: {$gte: ISODate()-ISODate('1970-01-01')-NumberLong(1000*60*60*24)}
}}, {$addFields: {
  sensorDate:    {$toDate: "$sensorTimestamp"},
  sensorDatePrt: {$dateToParts: {date: {$toDate: "$sensorTimestamp"} } },
  sensorDateStr: {$dateToString: {date: {$toDate: "$sensorTimestamp"}, format: "%Y-%m-%d %H:00", timezone: "Europe/Berlin"} }
}}, {$group: {
  _id: "$sensorDateStr",
  temp_avg: { $avg: "$temperature" },
  temp_min: { $min: "$temperature" },
  temp_max: { $max: "$temperature" },
  temp_std: { $stdDevSamp: "$temperature" },
  hum_avg: { $avg: "$humidity" },
  hum_min: { $min: "$humidity" },
  hum_max: { $max: "$humidity" },
  hum_std: { $stdDevSamp: "$humidity" },
  pres_avg: { $avg: "$pressure" },
  pres_min: { $min: "$pressure" },
  pres_max: { $max: "$pressure" },
  pres_std: { $stdDevSamp: "$pressure" },
  lght_avg: { $avg: "$lightlevel" },
  lght_min: { $min: "$lightlevel" },
  lght_max: { $max: "$lightlevel" },
  lght_std: { $stdDevSamp: "$lightlevel" },
  co2_avg: { $avg: "$co2" },
  co2_min: { $min: "$co2" },
  co2_max: { $max: "$co2" },
  co2_std: { $stdDevSamp: "$co2" },
  voc_avg: { $avg: "$voc" },
  voc_min: { $min: "$voc" },
  voc_max: { $max: "$voc" },
  voc_std: { $stdDevSamp: "$voc" },
  nbrData: { $sum: 1 }
}}, {$project: {
  nbrData:     1,
  temperature: {mean:"$temp_avg", std:"$temp_std", min: "$temp_min", max: "$temp_max"},
  humidity:    {mean:"$hum_avg",  std:"$hum_std",  min: "$hum_min",  max: "$hum_max"},
  pressure:    {mean:"$pres_avg", std:"$pres_std", min: "$pres_min", max: "$pres_max"},
  lightlevel:  {mean:"$lght_avg", std:"$lght_std", min: "$lght_min", max: "$lght_max"},
  co2:         {mean:"$co2_avg",  std:"$co2_std",  min: "$co2_min",  max: "$co2_max"},
  voc:         {mean:"$voc_avg",  std:"$voc_std",  min: "$voc_min",  max: "$voc_max"}
}}, {$sort: {
  _id: -1
}}
]
