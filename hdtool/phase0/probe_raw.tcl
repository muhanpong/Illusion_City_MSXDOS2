set throttle off
set power off
set power on
after time 10 { screenshot -prefix raw_t10_ }
after time 20 { screenshot -prefix raw_t20_ }
after time 20 { exit }
