namespace: jkJKAS
flow:
  name: akash
  workflow:
    - random_number_generator:
        do:
          io.cloudslang.base.math.random_number_generator:
            - min: '1'
            - max: '2'
        navigate:
          - SUCCESS:
              next_step: SUCCESS
              ROI: '3'
          - FAILURE: on_failure
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      random_number_generator:
        x: 480
        'y': 240
        navigate:
          d347acb9-98cf-a29c-e87d-e63216116c33:
            targetId: f31c240d-479f-1f54-f0fd-16319f9ee027
            port: SUCCESS
    results:
      SUCCESS:
        f31c240d-479f-1f54-f0fd-16319f9ee027:
          x: 880
          'y': 320
