SELECT *
FROM ieee.crime_scene_reports
WHERE
    location = 'Al-Muizz Street';

select *
from ieee.traffic_cameras
where
    location = 'Salah Salem Exit'
    and timestamp between '2026-02-16 23:15:??' and '2026-02-16 23:20:00'
    and car_make = 'Hyundai';

select *
from ieee.vehicle_owners
where
    license_plate = 'ن ي س - 4255';

select *
from ieee.sobia_king_sales
where
    timestamp BETWEEN '2026-02-16 22:30:00' AND '2026-02-16 23:15:00'
    AND order_details LIKE '%2 Sobia%'
    AND order_details LIKE '%1 Kharoub%';

select *
from ieee.phone_calls
where
    timestamp between '2026-02-16 23:15:00' and '2026-02-16 23:30:00'
    and caller_number = '010-9999-8888';

select *
from ieee.vehicle_owners
where
    phone_number = '011-7777-6666';

select *
from ieee.ramses_station_tickets
where
    national_id = '29011122233344'
    and departure_time > '2026-02-16 11:15:00';

select seat_number from ieee.ramses_station_tickets where id = 362;