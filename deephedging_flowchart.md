# Deep Hedging System Flowchart

## Entry Point: trainer.ipynb

```mermaid
flowchart TD
    A["trainer.ipynb - Main Entry Point"] --> B["Import Libraries & Setup"]
    B --> C["Create Config Object"]
    C --> D["Configure World Parameters"]
    D --> E["Configure Gym Parameters"]
    E --> F["Configure Trainer Parameters"]
    
    D --> D1["world.samples = 10000"]
    D --> D2["world.steps = 20"]
    D --> D3["world.black_scholes = True/False"]
    
    E --> E1["gym.objective.utility = 'cvar'"]
    E --> E2["gym.objective.lmbda = 1.0"]
    E --> E3["gym.agent.network.depth = 3"]
    E --> E4["gym.agent.network.activation = 'softplus'"]
    
    F --> F1["trainer.train.optimizer.name = 'adam'"]
    F --> F2["trainer.train.epochs = 800"]
    F --> F3["trainer.caching.mode = 'on'"]
    
    F --> G["Create World Objects"]
    G --> G1["world = SimpleWorld_Spot_ATM(config.world)"]
    G --> G2["val_world = world.clone(samples=world.nSamples//10)"]
    
    G --> H["Create Gym"]
    H --> H1["gym = VanillaDeepHedgingGym(config.gym)"]
    
    H --> I["Start Training"]
    I --> J["train(gym, world, val_world, config.trainer)"]
```

## World Creation (SimpleWorld_Spot_ATM)

```mermaid
flowchart TD
    A["SimpleWorld_Spot_ATM.__init__"] --> B["Parse Configuration"]
    B --> C["Simulator Parameters"]
    C --> C1["nSteps = 10"]
    C --> C2["nSamples = 1000"]
    C --> C3["seed = 2312414312"]
    C --> C4["dt = 1/50"]
    
    B --> D["Hedging Parameters"]
    D --> D1["strike = 1.0"]
    D --> D2["cost_s = 0.0002"]
    D --> D3["ubnd_as = 5.0"]
    D --> D4["lbnd_as = -5.0"]
    
    B --> E["Market Dynamics"]
    E --> E1["drift = 0.1"]
    E --> E2["rvol = 0.2"]
    E --> E3["ivol = 0.2"]
    E --> E4["correlations"]
    
    B --> F["Generate Market Data"]
    F --> F1["Simulate Asset Prices"]
    F --> F2["Simulate Volatility"]
    F --> F3["Compute Option Payoffs"]
    F --> F4["Generate Features"]
    
    F --> G["Create Data Dictionaries"]
    G --> G1["data.market.hedges"]
    G --> G2["data.market.cost"]
    G --> G3["data.market.ubnd_a/lbnd_a"]
    G --> G4["data.market.payoff"]
    G --> G5["data.features.per_step"]
    G --> G6["data.features.per_path"]
    
    G --> H["Convert to TensorFlow Tensors"]
    H --> I["Return world.tf_data"]
```

## Gym Creation (VanillaDeepHedgingGym)

```mermaid
flowchart TD
    A["VanillaDeepHedgingGym.__init__"] --> B["Parse Configuration"]
    B --> C["Create Components"]
    C --> C1["softclip = DHSoftClip"]
    C --> C2["config_agent = config.agent.detach()"]
    C --> C3["config_objective = config.objective.detach()"]
    
    B --> D["Set Random Seed"]
    D --> E["Initialize Agent & Utility as None"]
    
    E --> F["gym.build(shapes)"]
    F --> F1["Extract nInst from shapes"]
    F --> F2["agent = AgentFactory(nInst, config_agent)"]
    F --> F3["utility = MonetaryUtility(config_objective)"]
    F --> F4["utility0 = MonetaryUtility(config_objective)"]
```

## Agent Creation (AgentFactory)

```mermaid
flowchart TD
    A["AgentFactory"] --> B["Create SimpleDenseAgent"]
    B --> C["Parse Agent Configuration"]
    C --> C1["features = ['price', 'delta', 'time_left']"]
    C --> C2["network.depth = 3"]
    C --> C3["network.width = 64"]
    C --> C4["network.activation = 'softplus'"]
    
    C --> D["Create Network Layers"]
    D --> D1["_layer = DenseLayer"]
    D --> D2["_init_state = DenseLayer (if recurrent)"]
    D --> D3["_init_delta = DenseLayer (if initial_delta)"]
    
    D --> E["Return Agent"]
```

## Training Process (train function)

```mermaid
flowchart TD
    A["train function"] --> B["Parse Trainer Config"]
    B --> B1["output_level = 'all'"]
    B --> B2["batch_size = None"]
    B --> B3["epochs = 100"]
    B --> B4["run_eagerly = False"]
    
    B --> C["Initialize Training"]
    C --> C1["result0 = gym(world.tf_data)"]
    C --> C2["gym.compile(optimizer, loss, metrics)"]
    
    C --> D["Create TrainingInfo"]
    D --> E["Create Monitor (Callback)"]
    E --> E1["TrainingProgressData"]
    E --> E2["Cache Management"]
    E --> E3["Plotter Setup"]
    
    E --> F["Check Cache"]
    F --> F1{"Is Cache Available?"}
    F1 -->|Yes| F2["Restore from Cache"]
    F1 -->|No| F3["Start Fresh Training"]
    
    F2 --> G["Continue Training"]
    F3 --> G
    
    G --> H["gym.fit()"]
    H --> H1["Monitor.on_epoch_begin"]
    H --> H2["Process Batch"]
    H --> H3["Monitor.on_epoch_end"]
    H --> H4["Update Progress Data"]
    H --> H5["Plot Results"]
    H --> H6["Cache State"]
    
    H --> I{"More Epochs?"}
    I -->|Yes| H
    I -->|No| J["Finalize Training"]
    J --> J1["Restore Best Weights"]
    J --> J2["Final Plot"]
    J --> J3["Save Cache"]
```

## Main Training Loop (gym._call)

```mermaid
flowchart TD
    A["gym._call"] --> B["Extract Market Data"]
    B --> B1["hedges = data['market']['hedges']"]
    B --> B2["trading_cost = data['market']['cost']"]
    B --> B3["ubnd_a = data['market']['ubnd_a']"]
    B --> B4["lbnd_a = data['market']['lbnd_a']"]
    B --> B5["payoff = data['market']['payoff']"]
    
    B --> C["Extract Features"]
    C --> C1["features_per_step, features_per_path = _features(data, nSteps)"]
    
    C --> D["Initialize Variables"]
    D --> D1["pnl = zeros"]
    D --> D2["cost = zeros"]
    D --> D3["delta = zeros"]
    D --> D4["action = zeros"]
    D --> D5["actions = empty_tensor"]
    D --> D6["state = agent.initial_state()"]
    D --> D7["idelta = agent.initial_delta()"]
    
    D --> E["Main Trading Loop"]
    E --> E1{"t < nSteps?"}
    E1 -->|No| F["Compute Utility"]
    E1 -->|Yes| E2["Build Live Features"]
    
    E2 --> E2a["live_features = dict(action, delta, cost, pnl)"]
    E2 --> E2b["Add features_per_path"]
    E2 --> E2c["Add features_per_step[:,t,:]"]
    E2 --> E2d["Add recurrent state if applicable"]
    
    E2 --> E3["Agent Decision"]
    E3 --> E3a["action, state_ = agent(live_features, training)"]
    E3 --> E3b["action += idelta"]
    E3 --> E3c["action = softclip(action, lbnd_a[:,t,:], ubnd_a[:,t,:])"]
    E3 --> E3d["state = state_ if recurrent else state"]
    E3 --> E3e["delta += action"]
    
    E3 --> E4["Execute Trade"]
    E4 --> E4a["cost += sum(abs(action) * trading_cost[:,t,:])"]
    E4 --> E4b["pnl += sum(action * hedges[:,t,:])"]
    
    E4 --> E5["Record Actions"]
    E5 --> E5a["actions = concat(actions, action)"]
    E5 --> E5b["idelta *= 0"]
    E5 --> E5c["t += 1"]
    
    E5 --> E1
    
    F --> F1["utility = self.utility(features_time_0, payoff, pnl, cost)"]
    F --> F2["utility0 = self.utility0(features_time_0, payoff, 0, 0)"]
    
    F --> G["Return Results"]
    G --> G1["loss = -utility - utility0"]
    G --> G2["utility, utility0"]
    G --> G3["gains = payoff + pnl - cost"]
    G --> G4["payoff, pnl, cost"]
    G --> G5["actions"]
```

## Agent Decision Process (SimpleDenseAgent.call)

```mermaid
flowchart TD
    A["agent.call"] --> B{"Is Recurrent?"}
    B -->|No| C["Simple Forward Pass"]
    C --> C1["output = _layer(all_features)"]
    C --> C2["return output, None"]
    
    B -->|Yes| D["Recurrent Processing"]
    D --> D1["Extract State from Features"]
    D --> D2["Split State by Type"]
    D2 --> D2a["classic_state"]
    D2 --> D2b["aggregate_state"]
    D2 --> D2c["past_repr_state"]
    D2 --> D2d["event_state"]
    
    D2 --> E["Process States"]
    E --> E1["classic_state = tanh(classic_state)"]
    E --> E2["aggregate_state = tanh(aggregate_state) if bound"]
    E --> E3["event_state = unit(event_state)"]
    
    E --> F["Recompose State"]
    F --> G["Execute Network"]
    G --> G1["output = _layer(all_features)"]
    G --> G2["out_action = output[:,:nInst]"]
    G --> G3["out_recurrent = output[:,nInst:]"]
    
    G --> H["Process Recurrent Output"]
    H --> H1["Split Recurrent Output"]
    H --> H2["Update States"]
    H2 --> H2a["classic_state = tanh(new_classic)"]
    H2 --> H2b["aggregate_state = update_aggregate"]
    H2 --> H2c["past_repr_state = update_past_repr"]
    H2 --> H2d["event_state = update_event"]
    
    H2 --> I["Recompose New State"]
    I --> J["Return action, new_state"]
```

## Utility Computation (MonetaryUtility.call)

```mermaid
flowchart TD
    A["MonetaryUtility.call"] --> B["Extract Data"]
    B --> B1["features = data['features_time_0']"]
    B --> B2["payoff = data['payoff']"]
    B --> B3["pnl = data['pnl']"]
    B --> B4["cost = data['cost']"]
    
    B --> C["Compute Total Gains"]
    C --> C1["X = payoff + pnl - cost"]
    
    C --> D["Compute Utility"]
    D --> D1["y = self.y(features_time_0)"]
    D --> D2["utility = tf_utility(utility_type, lambda, X, y)"]
    
    D --> E["Return Utility Value"]
```

## Feature Processing (_features)

```mermaid
flowchart TD
    A["_features"] --> B["Extract Features from Data"]
    B --> B1["features = data.get('features', {})"]
    
    B --> C["Process Per-Step Features"]
    C --> C1["features_per_step_i = features.get('per_step', {})"]
    C --> C2["For each feature f in features_per_step_i"]
    C2 --> C2a["Validate tensor shape"]
    C2 --> C2b["features_per_step[f] = tf_make_dim(feature, 3)"]
    
    B --> D["Process Per-Path Features"]
    D --> D1["features_per_path_i = features.get('per_path', {})"]
    D --> D2["For each feature f in features_per_path_i"]
    D2 --> D2a["Validate tensor shape"]
    D2 --> D2b["features_per_path[f] = tf_make_dim(feature, 2)"]
    
    D --> E["Return features_per_step, features_per_path"]
```

## Monitoring & Visualization

```mermaid
flowchart TD
    A["Monitor.on_epoch_end"] --> B["Compute Full Results"]
    B --> B1["training_result = gym(world.tf_data)"]
    B --> B2["val_result = gym(val_world.tf_data)"]
    
    B --> C["Update Progress Data"]
    C --> C1["losses.training.append(mean(training_result.loss))"]
    C --> C2["losses.val.append(mean(val_result.loss))"]
    C --> C3["utilities.training_util.append(mean(training_result.utility))"]
    C --> C4["utilities.val_util.append(mean(val_result.utility))"]
    
    C --> D["Check Best Loss"]
    D --> D1{"training_loss < best_loss?"}
    D1 -->|Yes| D2["Update best_weights, best_epoch"]
    D1 -->|No| E["Continue"]
    
    D2 --> E
    E --> F{"Cache Frequency?"}
    F -->|Yes| G["Write Cache"]
    F -->|No| H["Continue"]
    
    G --> H
    H --> I["Update Plot"]
    I --> I1["Plotter(last_cached_epoch, progress_data, training_info)"]
```

## Key Data Flow Summary

```mermaid
flowchart LR
    A["Config"] --> B["World"]
    A --> C["Gym"]
    A --> D["Trainer"]
    
    B --> E["Market Data Generation"]
    E --> F["Asset Prices"]
    E --> G["Option Payoffs"]
    E --> H["Features"]
    
    C --> I["Agent Creation"]
    C --> J["Utility Creation"]
    
    I --> K["Neural Network"]
    J --> L["Monetary Utility"]
    
    F --> M["Training Loop"]
    G --> M
    H --> M
    K --> M
    L --> M
    
    M --> N["Loss Computation"]
    N --> O["Backpropagation"]
    O --> P["Weight Updates"]
    P --> Q["Next Epoch"]
    
    Q --> M
```

## Configuration Structure

```mermaid
flowchart TD
    A["Config"] --> B["world"]
    A --> C["gym"]
    A --> D["trainer"]
    
    B --> B1["samples: 10000"]
    B --> B2["steps: 20"]
    B --> B3["black_scholes: True/False"]
    B --> B4["drift: 0.1"]
    B --> B5["rvol: 0.2"]
    B --> B6["cost_s: 0.0002"]
    
    C --> C1["agent"]
    C --> C2["objective"]
    
    C1 --> C1a["network.depth: 3"]
    C1 --> C1b["network.width: 64"]
    C1 --> C1c["network.activation: 'softplus'"]
    C1 --> C1d["features: ['price', 'delta', 'time_left']"]
    
    C2 --> C2a["utility: 'cvar'"]
    C2 --> C2b["lmbda: 1.0"]
    
    D --> D1["train.epochs: 800"]
    D --> D2["train.optimizer.name: 'adam'"]
    D --> D3["caching.mode: 'on'"]
    D --> D4["visual.epoch_refresh: 5"]
``` 