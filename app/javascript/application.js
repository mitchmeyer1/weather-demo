// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails


document.addEventListener('DOMContentLoaded', function() {
  console.log('Home page script loaded');
  const fetchButton = document.getElementById('fetch-button');
  const dataDisplay = document.getElementById('data-display');
  const addressInput = document.getElementById('address-input');
  const errorMessage = document.getElementById('error-message');
  const currentWeather = document.getElementById('current-weather');
  const forecastTableContainer = document.getElementById('forecast-table-container');
  const unitToggle = document.getElementById('unit-toggle');

  let selectedAddress = '';
  let selectedZip = '';
  let selectedUnit = localStorage.getItem('last_unit') || 'C';
  unitToggle.value = selectedUnit;
  let lastApiData = null;

  // On page load, check localStorage for last_address and last_zip
  if (localStorage.getItem('last_address') && localStorage.getItem('last_zip')) {
    selectedAddress = localStorage.getItem('last_address');
    selectedZip = localStorage.getItem('last_zip');
    addressInput.value = selectedAddress;
  }

  const autocomplete = new google.maps.places.Autocomplete(addressInput, {
    types: ['address'],
    fields: ['address_components', 'formatted_address', 'geometry'],
    componentRestrictions: { country: 'us' }
  });

  autocomplete.addListener('place_changed', () => {
    const place = autocomplete.getPlace();
    selectedAddress = place.formatted_address || addressInput.value;
    selectedZip = '';
    if (place.address_components) {
      const zipComponent = place.address_components.find(comp => comp.types.includes('postal_code'));
      if (zipComponent) {
        selectedZip = zipComponent.long_name;
      }
    }
  });

  function cToF(c) { return Math.round((c * 9/5 + 32) * 10) / 10; }

  unitToggle.addEventListener('change', function() {
    localStorage.setItem('last_unit', unitToggle.value);
    if (lastApiData) {
      renderWeather(lastApiData);
    }
  });

  fetchButton.addEventListener('click', function() {
    errorMessage.textContent = '';
    currentWeather.textContent = '';
    forecastTableContainer.innerHTML = '';
    dataDisplay.style.display = 'none';
    dataDisplay.textContent = '';

    if (!selectedAddress && addressInput.value) {
      selectedAddress = addressInput.value;
    }
    if (!selectedZip && localStorage.getItem('last_zip')) {
      selectedZip = localStorage.getItem('last_zip');
    }

    if (!selectedAddress) {
      errorMessage.textContent = 'Please enter a valid address and select it from the dropdown.';
      return;
    }
    if (!selectedZip) {
      errorMessage.textContent = 'Missing or invalid zip parameter (select a more complete address).';
      return;
    }

    // Cache last address and zip in localStorage
    localStorage.setItem('last_address', selectedAddress);
    localStorage.setItem('last_zip', selectedZip);
    localStorage.setItem('last_unit', unitToggle.value);

    currentWeather.textContent = 'Loading...';

    const url = `/api/v1/data.json?zip=${encodeURIComponent(selectedZip)}`;
    fetch(url)
      .then(async response => {
        let data;
        try {
          data = await response.json();
        } catch (e) {
          throw new Error('Invalid JSON response');
        }
        if (!response.ok) {
          throw new Error(data?.error || 'Network response was not ok');
        }
        return data;
      })
      .then(data => {
        renderWeather(data);
      })
      .catch(error => {
        console.error('Error fetching weather data:');
        console.error(error);
        errorMessage.textContent = error.message;
        currentWeather.textContent = '';
        forecastTableContainer.innerHTML = '';
      });
  });


  // Helper function to get friendly day label
  function getFriendlyDayLabel(dateStr) {
    const dateParts = dateStr.split('-');
    const date = new Date(
      Number(dateParts[0]),
      Number(dateParts[1]) - 1, // JS months are 0-indexed
      Number(dateParts[2])
    );
    const today = new Date();
    const tomorrow = new Date();
    tomorrow.setDate(today.getDate() + 1);

    if (date.toDateString() === today.toDateString()) {
      return "Today";
    } else if (date.toDateString() === tomorrow.toDateString()) {
      return "Tomorrow";
    } else {
      return date.toLocaleDateString('en-US', { weekday: 'long' }); // e.g., Monday
    }
  }

  // Helper to format "June 16"
  function formatMonthDay(dateStr) {
    const dateParts = dateStr.split('-');
    const date = new Date(
      Number(dateParts[0]),
      Number(dateParts[1]) - 1, // JS months are 0-indexed
      Number(dateParts[2])
    );
    return date.toLocaleDateString('en-US', { month: 'long', day: 'numeric' });
  }

  function renderWeather(data) {
    lastApiData = data;
    const isF = unitToggle.value === 'F';

    // Show current weather
    if (data.current_weather && data.current_weather.temperature_2m !== undefined && data.current_weather.wind_speed_10m !== undefined) {
      const temp = isF ? cToF(data.current_weather.temperature_2m) : data.current_weather.temperature_2m;
      const tempUnit = isF ? '&deg;F' : '&deg;C';
      const precipType = data.current_weather.precipitation_type ? capitalize(data.current_weather.precipitation_type) : 'No precip.';

      currentWeather.innerHTML = `
        <span style='font-size:2em;'>${temp}${tempUnit}</span> &nbsp; | &nbsp; Wind: ${data.current_weather.wind_speed_10m} km/h <br> 
        <span style='font-size:1em;'>${precipType}</span>`;
    } else {
      currentWeather.textContent = 'No current weather data.';
    }

    // Show daily weather
    const dailyContainer = document.getElementById('daily-weather');
    dailyContainer.innerHTML = ''; // Clear old tiles

    if (data.daily_weather) {
      data.daily_weather.forEach(day => {
        console.log('Processing day:', day);
        const friendlyDay = getFriendlyDayLabel(day.time);
        const monthDay = formatMonthDay(day.time);
        const precip = day.precipitation_probability_max !== undefined && day.precipitation_type
          ? `${day.precipitation_probability_max}% ${capitalize(day.precipitation_type)}`
          : 'No precip.';
        const minTemp = isF ? cToF(day.temperature_2m_min) : day.temperature_2m_min;
        const maxTemp = isF ? cToF(day.temperature_2m_max) : day.temperature_2m_max;
        const tempUnit = isF ? '°F' : '°C';

        const dayTile = document.createElement('div');
        dayTile.className = 'day-tile';
        dayTile.innerHTML = `
          <div><strong>${friendlyDay}</strong></div>
          <div style="font-size: 0.8em;">${monthDay}</div>
          <div style="font-size: 0.8em;">${precip}</div>
          <div style="font-size: 0.8em;">${minTemp} - ${maxTemp}${tempUnit}</div>
        `;
        dailyContainer.appendChild(dayTile);
      });
    } else {
      dailyContainer.textContent = 'No daily weather data.';
    }
  }

  function capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
  }
});


