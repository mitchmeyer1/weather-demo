// Wait until the DOM is fully loaded
document.addEventListener('DOMContentLoaded', function () {
  // === DOM ELEMENT REFERENCES ===
  const fetchButton = document.getElementById('fetch-button');
  const dataDisplay = document.getElementById('data-display');
  const addressInput = document.getElementById('address-input');
  const errorMessage = document.getElementById('error-message');
  const sourceMessage = document.getElementById('source-message');
  const currentWeather = document.getElementById('current-weather');
  const forecastTableContainer = document.getElementById('forecast-table-container');
  const unitToggle = document.getElementById('unit-toggle');

  // === STATE VARIABLES ===
  let selectedAddress = '';
  let selectedZip = '';
  let selectedUnit = localStorage.getItem('last_unit') || 'C'; // Default to Celsius
  let lastApiData = null;

  // Initialize unit toggle value from storage
  unitToggle.value = selectedUnit;

  // Restore address and zip from localStorage if available
  if (localStorage.getItem('last_address') && localStorage.getItem('last_zip')) {
    selectedAddress = localStorage.getItem('last_address');
    selectedZip = localStorage.getItem('last_zip');
    addressInput.value = selectedAddress;
  }

  // === AUTOCOMPLETE SETUP (Google Maps Places API) ===
  const autocomplete = new google.maps.places.Autocomplete(addressInput, {
    types: ['address'],
    fields: ['address_components', 'formatted_address', 'geometry'],
    componentRestrictions: { country: 'us' }
  });

  // Capture selected place and extract ZIP code
  autocomplete.addListener('place_changed', () => {
    const place = autocomplete.getPlace();
    selectedAddress = place.formatted_address || addressInput.value;
    selectedZip = '';

    if (place.address_components) {
      const zipComponent = place.address_components.find(comp =>
        comp.types.includes('postal_code')
      );
      if (zipComponent) {
        selectedZip = zipComponent.long_name;
      }
    }
  });

  // === UTILITY FUNCTIONS ===

  function cToF(c) {
    return Math.round((c * 9 / 5 + 32) * 10) / 10;
  }

  function capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
  }

  function getFriendlyDayLabel(dateStr) {
    const [year, month, day] = dateStr.split('-').map(Number);
    const date = new Date(year, month - 1, day);
    const today = new Date();
    const tomorrow = new Date();
    tomorrow.setDate(today.getDate() + 1);

    if (date.toDateString() === today.toDateString()) return "Today";
    if (date.toDateString() === tomorrow.toDateString()) return "Tomorrow";

    return date.toLocaleDateString('en-US', { weekday: 'long' });
  }

  function formatMonthDay(dateStr) {
    const [year, month, day] = dateStr.split('-').map(Number);
    const date = new Date(year, month - 1, day);
    return date.toLocaleDateString('en-US', { month: 'long', day: 'numeric' });
  }

  // === UNIT TOGGLE EVENT HANDLER ===
  unitToggle.addEventListener('change', function () {
    localStorage.setItem('last_unit', unitToggle.value);
    if (lastApiData) {
      renderWeather(lastApiData); // Re-render in new unit
    }
  });

  // === FETCH BUTTON EVENT HANDLER ===
  fetchButton.addEventListener('click', function () {
    // Clear previous messages and data
    errorMessage.textContent = '';
    sourceMessage.textContent = '';
    currentWeather.textContent = '';
    forecastTableContainer.innerHTML = '';
    dataDisplay.style.display = 'none';
    dataDisplay.textContent = '';

    // Backup input to selectedAddress if needed
    if (!selectedAddress && addressInput.value) {
      selectedAddress = addressInput.value;
    }

    if (!selectedZip && localStorage.getItem('last_zip')) {
      selectedZip = localStorage.getItem('last_zip');
    }

    // Input validation
    if (!selectedAddress) {
      errorMessage.textContent = 'Please enter a valid address and select it from the dropdown.';
      return;
    }

    if (!selectedZip) {
      errorMessage.textContent = 'Missing or invalid zip parameter (select a more complete address).';
      return;
    }

    // Save user preferences
    localStorage.setItem('last_address', selectedAddress);
    localStorage.setItem('last_zip', selectedZip);
    localStorage.setItem('last_unit', unitToggle.value);

    // Indicate loading
    currentWeather.textContent = 'Loading...';

    // Fetch weather data
    const url = `/api/v1/data.json?zip=${encodeURIComponent(selectedZip)}`;

    fetch(url)
      .then(async response => {
        let data;
        try {
          data = await response.json();
        } catch {
          throw new Error('Invalid JSON response');
        }
        if (!response.ok) {
          throw new Error(data?.error || 'Network response was not ok');
        }
        return data;
      })
      .then(data => {
        console.log('Weather data:');
        console.log(JSON.stringify(data));
        sourceMessage.textContent = `Data retrieved from ${data.source}`;
        renderWeather(data);
      })
      .catch(error => {
        console.error('Error fetching weather data:', error);
        errorMessage.textContent = error.message;
        currentWeather.textContent = '';
        forecastTableContainer.innerHTML = '';
        sourceMessage.textContent = '';

      });
  });

  // === WEATHER RENDERING ===
  function renderWeather(data) {
    lastApiData = data;
    const isFahrenheit = unitToggle.value === 'F';

    // === CURRENT WEATHER ===
    if (data.current_weather?.temperature_2m !== undefined && data.current_weather?.wind_speed_10m !== undefined) {
      const temp = isFahrenheit ? cToF(data.current_weather.temperature_2m) : data.current_weather.temperature_2m;
      const unit = isFahrenheit ? '&deg;F' : '&deg;C';
      const precip = data.current_weather.precipitation_type
        ? capitalize(data.current_weather.precipitation_type)
        : 'No precipitation';

      currentWeather.innerHTML = `
        <span style='font-size:2em;'>${Math.round(temp)}${unit}</span><br>
        Wind: ${data.current_weather.wind_speed_10m} km/h<br>
        <span style='font-size:1em;'>${precip}</span>`;
    } else {
      currentWeather.textContent = 'No current weather data.';
    }

    // === DAILY FORECAST ===
    const dailyContainer = document.getElementById('daily-weather');
    dailyContainer.innerHTML = ''; // Clear previous tiles

    if (data.daily_weather?.length) {
      data.daily_weather.forEach(day => {
        const friendlyDay = getFriendlyDayLabel(day.time);
        const monthDay = formatMonthDay(day.time);
        const precipText = day.precipitation_probability_max !== undefined && day.precipitation_type
          ? `${day.precipitation_probability_max}% ${capitalize(day.precipitation_type)}`
          : 'No precipitation';
        const min = isFahrenheit ? cToF(day.temperature_2m_min) : day.temperature_2m_min;
        const max = isFahrenheit ? cToF(day.temperature_2m_max) : day.temperature_2m_max;
        const unit = isFahrenheit ? '°F' : '°C';

        const dayTile = document.createElement('div');
        dayTile.className = 'day-tile';
        dayTile.innerHTML = `
          <div><strong>${friendlyDay}</strong></div>
          <div style="font-size: 0.8em;">${monthDay}</div>
          <div style="font-size: 0.8em;">${precipText}</div>
          <div style="font-size: 0.8em;">${Math.round(min)} - ${Math.round(max)}${unit}</div>
        `;
        dailyContainer.appendChild(dayTile);
      });
    } else {
      dailyContainer.textContent = 'No daily weather data.';
    }
  }
});