from locust import HttpUser, task, between

class StadiumCrowdSimUser(HttpUser):
    # Simulate a fan or edge sensor polling/pushing data at realistic intervals
    wait_time = between(0.5, 2.0)

    @task(3)
    def fetch_dashboard_kpis(self):
        """Simulate a fan device opening the dashboard to check live stadium metrics."""
        # In a real deployed environment, this hits the API Gateway or Firebase RTDB REST API
        # Using a simulated endpoint for the Load Test framework
        self.client.get("/zones/Z-101/metrics", name="Get Zone KPIs")

    @task(1)
    def post_edge_sensor_data(self):
        """Simulate a UWB anchor (Edge Node) pushing a batch of kinematic crowd vectors."""
        payload = {
            "zone_id": "Z-101",
            "density_ppm2": 4.2,
            "velocity_x": 1.1,
            "velocity_y": -0.5,
            "speed_p95": 1.25,
            "heading_deg": 115.0,
            "dwell_ratio": 0.82
        }
        self.client.post("/ingest/vectors", json=payload, name="Push Edge Vectors")
